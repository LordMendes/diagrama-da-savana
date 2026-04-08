defmodule DiagramaSavana.Accounts.Tokens do
  @moduledoc """
  Emite pares de JWT (acesso curto + renovação longa) via Guardian.
  """

  alias DiagramaSavana.Accounts.Guardian, as: G

  @doc """
  Retorna `{access_token, renewal_token}` para o cliente (header Authorization).
  """
  def issue_pair(user) do
    auth = Application.get_env(:diagrama_savana, :auth, [])
    access_ttl = Keyword.get(auth, :access_token_ttl_minutes, 15)
    renewal_days = Keyword.get(auth, :renewal_token_ttl_days, 7)

    with {:ok, access, _} <-
           G.encode_and_sign(user, %{}, ttl: {access_ttl, :minutes}),
         {:ok, renewal, _} <-
           G.encode_and_sign(user, %{}, token_type: "refresh", ttl: {renewal_days, :days}) do
      {:ok, access, renewal}
    end
  end
end
