defmodule DiagramaSavanaWeb.API.V1.RegistrationController do
  use DiagramaSavanaWeb, :api

  alias DiagramaSavana.Accounts
  alias DiagramaSavana.Accounts.Tokens
  alias DiagramaSavanaWeb.ApiJSON

  def create(conn, %{"user" => user_params}) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, access, renewal} = Tokens.issue_pair(user)

        conn
        |> put_status(:created)
        |> json(%{
          data: %{
            access_token: access,
            renewal_token: renewal,
            user: %{id: user.id, email: user.email}
          }
        })

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          error: %{
            code: "validacao_falhou",
            message: "Não foi possível criar a conta.",
            fields: ApiJSON.changeset_errors(changeset)
          }
        })
    end
  end

  def create(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{
      error: %{
        code: "corpo_invalido",
        message: "Envie um objeto \"user\" com email e senha."
      }
    })
  end
end
