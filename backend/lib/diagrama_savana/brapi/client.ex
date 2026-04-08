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

  require Logger

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

  **Cripto** (BTC, ETH, …): usa `/v2/crypto?coin=…&currency=BRL`, não `/quote/`, para
  preço coerente em real (a rota de ações mistura instrumentos e valores incorretos).

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
        with :ok <- DiagramaSavana.Brapi.RateLimiter.acquire(:quote),
             {:ok, body} <- fetch_quote_http(ticker, opts),
             :ok <- DiagramaSavana.Brapi.Cache.put(cache_key, body, ttl: cache_ttl()) do
          {:ok, body}
        else
          {:error, :rate_limited} = e -> e
          {:error, reason} -> {:error, reason}
        end
    end
  end

  # Cripto: `/quote/BTC` da brapi não reflete preço em BRL; usar `/v2/crypto?coin=…&currency=BRL`.
  defp fetch_quote_http(ticker, opts) do
    extra = quote_query_params(opts)

    if DiagramaSavana.Brapi.CryptoFallback.crypto_symbol?(ticker) do
      params = [coin: ticker, currency: "BRL"] ++ extra

      with {:ok, raw} <- get_json("/v2/crypto", params),
           {:ok, body} <- v2_crypto_body_to_quote(ticker, raw) do
        {:ok, body}
      end
    else
      get_json("/quote/" <> ticker, extra)
    end
  end

  defp v2_crypto_body_to_quote(wanted_ticker, body) when is_binary(wanted_ticker) do
    wanted = String.upcase(String.trim(wanted_ticker))

    case body do
      %{"coins" => coins} when is_list(coins) ->
        row =
          Enum.find_value(coins, fn c ->
            if is_map(c) and crypto_coin_symbol(c) == wanted do
              {:ok, crypto_coin_to_quote_row(c)}
            else
              false
            end
          end)

        case row do
          {:ok, r} -> {:ok, %{"results" => [r]}}
          _ -> {:error, :http_error}
        end

      _ ->
        {:error, :http_error}
    end
  end

  defp crypto_coin_symbol(row) when is_map(row) do
    s = row["coin"] || row["symbol"]
    if is_binary(s), do: String.upcase(String.trim(s)), else: nil
  end

  defp crypto_coin_to_quote_row(row) when is_map(row) do
    sym = crypto_coin_symbol(row) || row["symbol"] || "?"

    price =
      row["regularMarketPrice"] || row["price"] || row["lastPrice"] ||
        get_in(row, ["market_data", "current_price", "brl"])

    pct = row["regularMarketChangePercent"] || row["changePercent"]

    %{
      "symbol" => sym,
      "shortName" => row["shortName"] || row["name"] || sym,
      "currency" => row["currency"] || "BRL",
      "regularMarketPrice" => price,
      "regularMarketChangePercent" => pct
    }
    |> Enum.reject(fn {_, v} -> is_nil(v) end)
    |> Map.new()
  end

  defp index_v2_crypto_coins(%{"coins" => coins}) when is_list(coins) do
    Enum.reduce(coins, %{}, fn row, acc ->
      if is_map(row) do
        case crypto_coin_symbol(row) do
          nil -> acc
          sym -> Map.put(acc, sym, crypto_coin_to_quote_row(row))
        end
      else
        acc
      end
    end)
  end

  defp index_v2_crypto_coins(_), do: %{}

  @doc """
  Busca cotações para vários tickers com o mínimo de chamadas HTTP à brapi.

  Por padrão usa **uma requisição por ticker** (`/quote/TICKER`), compatível com o
  plano gratuito da brapi (1 ativo por chamada). Cotação em lote (`/quote/A,B,...`)
  só é usada se `BRAPI_QUOTE_BATCH_ENABLED=true` **e** `quote_batch_size` > 1 — para
  planos pagos. Se um lote falhar, faz fallback para `fetch_quote/2`.

  Resultado por ticker é o mesmo formato de `fetch_quote/2` (`%{"results" => [row]}`)
  para compatibilidade com `Simulacao` e `PortfolioSummary`.
  """
  @spec fetch_quotes_many([String.t()], quote_opts()) ::
          %{String.t() => {:ok, map()} | :error}
  def fetch_quotes_many(tickers, opts \\ []) when is_list(tickers) do
    normalized =
      tickers
      |> Enum.map(&normalize_ticker/1)
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()

    {cached, missing} =
      Enum.reduce(normalized, {%{}, []}, fn ticker, {cm, ms} ->
        key = quote_cache_key(ticker, opts)

        case DiagramaSavana.Brapi.Cache.get(key) do
          {:ok, body} -> {Map.put(cm, ticker, {:ok, body}), ms}
          :miss -> {cm, [ticker | ms]}
        end
      end)

    missing = Enum.reverse(missing)
    fetched = fetch_quotes_batches(missing, opts)
    Map.merge(cached, fetched)
  end

  defp normalize_ticker(ticker) when is_binary(ticker) do
    t = ticker |> String.trim() |> String.upcase()
    if t == "", do: nil, else: t
  end

  defp fetch_quotes_batches([], _opts), do: %{}

  defp fetch_quotes_batches(tickers, opts) do
    # brapi may reject a single `/quote/A,B,...` mixing B3 assets with crypto; keep batches homogeneous.
    {equities, cryptos} =
      Enum.split_with(tickers, &(not DiagramaSavana.Brapi.CryptoFallback.crypto_symbol?(&1)))

    if quote_batch_http_enabled?() do
      equities
      |> Enum.chunk_every(quote_batch_size())
      |> Enum.reduce(%{}, fn chunk, acc -> Map.merge(acc, fetch_quotes_chunk(chunk, opts)) end)
      |> Map.merge(
        cryptos
        |> Enum.chunk_every(quote_batch_size())
        |> Enum.reduce(%{}, fn chunk, acc -> Map.merge(acc, fetch_quotes_chunk(chunk, opts)) end)
      )
    else
      Map.merge(
        fetch_quotes_one_by_one(equities, opts),
        fetch_quotes_one_by_one(cryptos, opts)
      )
    end
  end

  defp quote_batch_http_enabled? do
    Application.get_env(:diagrama_savana, :brapi, [])
    |> Keyword.get(:quote_batch_http_enabled, false)
  end

  defp fetch_quotes_chunk(tickers, opts) when is_list(tickers) do
    case tickers do
      [] ->
        %{}

      [first | _] ->
        if DiagramaSavana.Brapi.CryptoFallback.crypto_symbol?(first) do
          fetch_crypto_quotes_chunk(tickers, opts)
        else
          fetch_equity_quotes_chunk(tickers, opts)
        end
    end
  end

  defp fetch_equity_quotes_chunk(tickers, opts) when is_list(tickers) do
    extra = quote_query_params(opts)
    path = "/quote/" <> Enum.join(tickers, ",")

    with :ok <- DiagramaSavana.Brapi.RateLimiter.acquire(:quote),
         {:ok, body} <- get_json(path, extra) do
      index = index_quote_results(body)

      Map.new(tickers, fn t ->
        case Map.get(index, t) do
          nil ->
            {t, :error}

          row ->
            single = %{"results" => [row]}
            key = quote_cache_key(t, opts)
            _ = DiagramaSavana.Brapi.Cache.put(key, single, ttl: cache_ttl())
            {t, {:ok, single}}
        end
      end)
    else
      {:error, :rate_limited} ->
        Map.new(tickers, fn t -> {t, :error} end)

      {:error, _} when length(tickers) > 1 ->
        Logger.debug(
          "brapi: batch quote failed, falling back to single-ticker requests (n=#{length(tickers)})"
        )

        fetch_quotes_one_by_one(tickers, opts)

      {:error, _} ->
        Map.new(tickers, fn t -> {t, :error} end)
    end
  end

  defp fetch_crypto_quotes_chunk(tickers, opts) when is_list(tickers) do
    extra = quote_query_params(opts)
    coin_param = Enum.join(tickers, ",")
    params = [coin: coin_param, currency: "BRL"] ++ extra

    with :ok <- DiagramaSavana.Brapi.RateLimiter.acquire(:quote),
         {:ok, raw} <- get_json("/v2/crypto", params) do
      index = index_v2_crypto_coins(raw)

      Map.new(tickers, fn t ->
        case Map.get(index, t) do
          nil ->
            {t, :error}

          row ->
            single = %{"results" => [row]}
            key = quote_cache_key(t, opts)
            _ = DiagramaSavana.Brapi.Cache.put(key, single, ttl: cache_ttl())
            {t, {:ok, single}}
        end
      end)
    else
      {:error, :rate_limited} ->
        Map.new(tickers, fn t -> {t, :error} end)

      {:error, _} when length(tickers) > 1 ->
        Logger.debug(
          "brapi: v2/crypto batch failed, falling back to single-ticker (n=#{length(tickers)})"
        )

        fetch_quotes_one_by_one(tickers, opts)

      {:error, _} ->
        Map.new(tickers, fn t -> {t, :error} end)
    end
  end

  defp fetch_quotes_one_by_one(tickers, opts) when is_list(tickers) do
    Enum.reduce(tickers, %{}, fn t, acc ->
      case fetch_quote(t, opts) do
        {:ok, body} -> Map.put(acc, t, {:ok, body})
        _ -> Map.put(acc, t, :error)
      end
    end)
  end

  defp index_quote_results(%{"results" => results}) when is_list(results) do
    Enum.reduce(results, %{}, fn row, acc ->
      if is_map(row) do
        sym = row["symbol"] || row["shortName"]

        if is_binary(sym) and sym != "" do
          Map.put(acc, String.upcase(String.trim(sym)), row)
        else
          acc
        end
      else
        acc
      end
    end)
  end

  defp index_quote_results(_), do: %{}

  defp quote_batch_size do
    Application.get_env(:diagrama_savana, :brapi, [])
    |> Keyword.get(:quote_batch_size, 1)
    |> max(1)
  end

  defp quote_cache_key(ticker, []), do: {:quote, quote_cache_bucket(ticker), ticker}

  defp quote_cache_key(ticker, opts) do
    sorted = opts |> Enum.sort() |> :erlang.term_to_binary()
    {:quote, quote_cache_bucket(ticker), ticker, :crypto.hash(:sha256, sorted)}
  end

  defp quote_cache_bucket(ticker) do
    if DiagramaSavana.Brapi.CryptoFallback.crypto_symbol?(ticker),
      do: :crypto_brl_v2,
      else: :equity
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
