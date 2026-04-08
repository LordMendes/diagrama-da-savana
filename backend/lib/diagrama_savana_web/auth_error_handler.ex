defmodule DiagramaSavanaWeb.AuthErrorHandler do
  @moduledoc """
  Respostas JSON para falhas do Guardian (pt-BR, código mapeável).
  """
  @behaviour Guardian.Plug.ErrorHandler

  import Plug.Conn

  @impl Guardian.Plug.ErrorHandler
  def auth_error(conn, {reason, _detail}, _opts) do
    {status, code, message} = map_reason(reason)

    body = Jason.encode!(%{error: %{code: code, message: message}})

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, body)
  end

  defp map_reason(:token_not_found), do: {401, "token_ausente", "Token ausente ou inválido."}
  defp map_reason(:invalid_token), do: {401, "token_invalido", "Token inválido ou expirado."}
  defp map_reason(:unauthenticated), do: {401, "nao_autenticado", "Não autenticado."}
  defp map_reason(:already_authenticated), do: {403, "ja_autenticado", "Já autenticado."}
  defp map_reason(:no_resource), do: {401, "recurso_indisponivel", "Sessão inválida."}
  defp map_reason(_), do: {401, "nao_autenticado", "Não autenticado."}
end
