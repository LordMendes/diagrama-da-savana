defmodule DiagramaSavanaWeb.API.V1.MarketController do
  use DiagramaSavanaWeb, :api

  alias DiagramaSavana.Brapi.Client

  @doc """
  Proxy para busca de tickers (autocomplete) — `q` é o termo digitado.
  """
  def search(conn, params) do
    q = params["q"] || ""

    case Client.search_tickers(q) do
      {:ok, body} ->
        json(conn, %{data: body})

      {:error, :rate_limited} ->
        conn
        |> put_status(:too_many_requests)
        |> json(%{
          error: %{
            code: "limite_cotacoes",
            message:
              "Muitas consultas ao serviço de cotações. Aguarde um instante e tente novamente."
          }
        })

      {:error, :http_error} ->
        service_unavailable(conn)

      {:error, _reason} ->
        service_unavailable(conn)
    end
  end

  @doc """
  Cotação atual e, opcionalmente, histórico (`range`, `interval` como na brapi).
  """
  def quote(conn, %{"ticker" => ticker} = params) do
    opts =
      []
      |> maybe_put_opt(:range, params["range"])
      |> maybe_put_opt(:interval, params["interval"])

    case Client.fetch_quote(ticker, opts) do
      {:ok, body} ->
        json(conn, %{data: body})

      {:error, :rate_limited} ->
        conn
        |> put_status(:too_many_requests)
        |> json(%{
          error: %{
            code: "limite_cotacoes",
            message:
              "Muitas consultas ao serviço de cotações. Aguarde um instante e tente novamente."
          }
        })

      {:error, :http_error} ->
        service_unavailable(conn)

      {:error, _reason} ->
        service_unavailable(conn)
    end
  end

  defp maybe_put_opt(kw, _key, nil), do: kw
  defp maybe_put_opt(kw, _key, v) when is_binary(v) and v == "", do: kw
  defp maybe_put_opt(kw, key, v) when is_binary(v), do: Keyword.put(kw, key, v)
  defp maybe_put_opt(kw, _key, _v), do: kw

  defp service_unavailable(conn) do
    conn
    |> put_status(:bad_gateway)
    |> json(%{
      error: %{
        code: "cotacoes_indisponivel",
        message: "Não foi possível obter cotações no momento. Tente novamente em instantes."
      }
    })
  end
end
