defmodule DiagramaSavana.Brapi.Client do
  @moduledoc """
  HTTP client for [brapi.dev](https://brapi.dev).

  All outbound calls go through `DiagramaSavana.Brapi.RateLimiter` and may use
  `DiagramaSavana.Brapi.Cache` for idempotent reads (quotes, search, etc.).

  Configure base URL and optional token via `:brapi` application env or
  `BRAPI_BASE_URL` / `BRAPI_API_TOKEN` (or `BRAPI_TOKEN`).

  HTTP is delegated to `DiagramaSavana.Brapi.ReqTransport` by default; tests use
  `DiagramaSavana.Brapi.TransportMock` (see `config/test.exs`).
  """

  @type quote_opts :: [range: String.t(), interval: String.t()]

  @doc """
  Searches tickers (ações, FIIs, ETFs) via `/available?search=` and merges
  criptomoedas from `/v2/crypto/available?search=` into the `stocks` list.

  Empty `query` returns an empty result without calling the API (saves quota).
  """
  @spec search_tickers(String.t()) ::
          {:ok, map()} | {:error, :rate_limited | :http_error | term()}
  def search_tickers(query) when is_binary(query) do
    q = String.trim(query)

    if q == "" do
      {:ok, %{"indexes" => [], "stocks" => []}}
    else
      cache_key = {:available_search, String.downcase(q)}

      case DiagramaSavana.Brapi.Cache.get(cache_key) do
        {:ok, cached} ->
          {:ok, cached}

        :miss ->
          case DiagramaSavana.Brapi.RateLimiter.acquire(:available) do
            {:error, :rate_limited} = e ->
              e

            :ok ->
              case get_json("/available", search: q) do
                {:error, :rate_limited} = e ->
                  e

                {:error, reason} ->
                  {:error, reason}

                {:ok, body} ->
                  merged = merge_crypto_search_results(body, q)

                  case DiagramaSavana.Brapi.Cache.put(cache_key, merged, ttl: cache_ttl()) do
                    :ok -> {:ok, merged}
                  end
              end
          end
      end
    end
  end

  defp merge_crypto_search_results(body, q) when is_map(body) do
    stocks = Map.get(body, "stocks", [])
    stocks = if is_list(stocks), do: stocks, else: []

    extras = fetch_crypto_coin_tickers(q)
    Map.put(body, "stocks", stocks ++ extras)
  end

  defp fetch_crypto_coin_tickers(q) do
    api_coins =
      case DiagramaSavana.Brapi.RateLimiter.acquire(:available) do
        {:error, :rate_limited} ->
          []

        :ok ->
          case get_json("/v2/crypto/available", search: q) do
            {:ok, %{"coins" => coins}} when is_list(coins) ->
              coins |> Enum.filter(&is_binary/1)

            {:ok, _} ->
              []

            {:error, _} ->
              []
          end
      end

    coins =
      if api_coins != [] do
        api_coins
      else
        DiagramaSavana.Brapi.CryptoFallback.matching(q)
      end

    Enum.map(coins, &String.upcase/1)
  end

  @doc """
  Fetches quote data for a ticker (e.g. `\"PETR4\"`).

  Optional `opts` are passed to brapi as query params:

  - `:range` — e.g. `\"1mo\"`, `\"1y\"` (historical candles)
  - `:interval` — e.g. `\"1d\"`

  Returns decoded JSON map on success. Errors are tagged tuples suitable for logging
  without leaking secrets to end users.
  """
  @spec fetch_quote(String.t(), quote_opts()) ::
          {:ok, map()} | {:error, :rate_limited | :http_error | term()}
  def fetch_quote(ticker, opts \\ [])

  def fetch_quote(ticker, opts) when is_binary(ticker) and is_list(opts) do
    ticker = String.upcase(String.trim(ticker))
    cache_key = quote_cache_key(ticker, opts)

    case DiagramaSavana.Brapi.Cache.get(cache_key) do
      {:ok, cached} ->
        {:ok, cached}

      :miss ->
        extra = quote_query_params(opts)

        with :ok <- DiagramaSavana.Brapi.RateLimiter.acquire(:quote),
             {:ok, body} <- get_json("/quote/" <> ticker, extra),
             :ok <- DiagramaSavana.Brapi.Cache.put(cache_key, body, ttl: cache_ttl()) do
          {:ok, body}
        else
          {:error, :rate_limited} = e -> e
          {:error, reason} -> {:error, reason}
        end
    end
  end

  defp quote_cache_key(ticker, []), do: {:quote, ticker}

  defp quote_cache_key(ticker, opts) do
    sorted = opts |> Enum.sort() |> :erlang.term_to_binary()
    {:quote, ticker, :crypto.hash(:sha256, sorted)}
  end

  defp quote_query_params(opts) do
    opts
    |> Keyword.take([:range, :interval])
    |> Enum.reject(fn {_, v} -> is_nil(v) or (is_binary(v) and String.trim(v) == "") end)
  end

  defp cache_ttl do
    Application.get_env(:diagrama_savana, :brapi_cache, [])
    |> Keyword.get(:default_ttl_seconds, 60)
  end

  defp get_json(path, extra_params) when is_binary(path) and is_list(extra_params) do
    {base_url, token} = brapi_config()
    url = merge_url(base_url, path)
    params = merge_params(extra_params, token)
    transport().get(url, params)
  end

  defp transport do
    Application.get_env(:diagrama_savana, :brapi_transport, DiagramaSavana.Brapi.ReqTransport)
  end

  defp merge_params(extra, token) do
    Keyword.merge(extra, token_query_params(token))
  end

  defp merge_url(base, path) do
    base = String.trim_trailing(base, "/")
    path = if String.starts_with?(path, "/"), do: path, else: "/" <> path
    base <> path
  end

  defp token_query_params(nil), do: []
  defp token_query_params(""), do: []
  defp token_query_params(token) when is_binary(token), do: [token: token]

  defp brapi_config do
    cfg = Application.get_env(:diagrama_savana, :brapi, [])
    {Keyword.get(cfg, :base_url, "https://brapi.dev/api"), Keyword.get(cfg, :api_token)}
  end
end
