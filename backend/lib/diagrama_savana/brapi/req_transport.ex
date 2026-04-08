defmodule DiagramaSavana.Brapi.ReqTransport do
  @moduledoc false

  @behaviour DiagramaSavana.Brapi.Transport

  require Logger

  @impl true
  def get(url, params) when is_binary(url) and is_list(params) do
    case Req.get(url, params: params, receive_timeout: 15_000) do
      {:ok, %Req.Response{status: 200, body: body}} when is_map(body) ->
        {:ok, body}

      {:ok, %Req.Response{status: 200, body: body}} when is_binary(body) ->
        case Jason.decode(body) do
          {:ok, map} when is_map(map) -> {:ok, map}
          _ -> {:error, :invalid_json}
        end

      {:ok, %Req.Response{status: 429}} ->
        Logger.warning("brapi rate limited url=#{scrub_url(url)}")
        {:error, :rate_limited}

      {:ok, %Req.Response{status: status}} ->
        Logger.warning("brapi HTTP status=#{status} url=#{scrub_url(url)}")
        {:error, :http_error}

      {:error, reason} ->
        Logger.warning("brapi request failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp scrub_url(url) do
    # Avoid logging full query (may contain token)
    case URI.parse(url) do
      %URI{path: path} when is_binary(path) -> path
      _ -> "/"
    end
  end
end
