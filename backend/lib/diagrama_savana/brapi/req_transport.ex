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

      {:ok, %Req.Response{status: status, body: body}} ->
        path = scrub_url(url)

        if status in [401, 403, 404] and String.contains?(path, "crypto/available") do
          Logger.debug("brapi HTTP status=#{status} url=#{path}")
        else
          Logger.warning("brapi HTTP status=#{status} url=#{path}")
          log_brapi_error_detail(status, body)
        end

        {:error, :http_error}

      {:error, reason} ->
        Logger.warning("brapi request failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp log_brapi_error_detail(status, body) when status in [400, 402, 403, 422] do
    body_map = error_body_map(body)

    msg =
      cond do
        is_binary(body_map["message"]) and body_map["message"] != "" -> body_map["message"]
        is_binary(body_map["code"]) and body_map["code"] != "" -> inspect(body_map["code"])
        true -> nil
      end

    if is_binary(msg) and msg != "" do
      Logger.debug("brapi error detail: #{msg}")
    end
  end

  defp log_brapi_error_detail(_status, _body), do: :ok

  defp error_body_map(body) when is_map(body), do: body

  defp error_body_map(body) when is_binary(body) do
    case Jason.decode(body) do
      {:ok, map} when is_map(map) -> map
      _ -> %{}
    end
  end

  defp error_body_map(_), do: %{}

  defp scrub_url(url) do
    # Avoid logging full query (may contain token)
    case URI.parse(url) do
      %URI{path: path} when is_binary(path) -> path
      _ -> "/"
    end
  end
end
