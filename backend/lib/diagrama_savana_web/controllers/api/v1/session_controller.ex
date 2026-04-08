defmodule DiagramaSavanaWeb.API.V1.SessionController do
  use DiagramaSavanaWeb, :api

  import Guardian.Plug, only: [current_resource: 1]

  alias DiagramaSavana.Accounts
  alias DiagramaSavana.Accounts.Tokens

  def create(conn, %{"user" => %{"email" => email, "password" => password}})
      when is_binary(email) and is_binary(password) do
    case Accounts.authenticate_user(email, password) do
      {:ok, user} ->
        {:ok, access, renewal} = Tokens.issue_pair(user)

        json(conn, %{
          data: %{
            access_token: access,
            renewal_token: renewal,
            user: %{id: user.id, email: user.email}
          }
        })

      {:error, :invalid_credentials} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{
          error: %{
            code: "credenciais_invalidas",
            message: "E-mail ou senha incorretos."
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
        message: "Envie user.email e user.password."
      }
    })
  end

  def delete(conn, _params) do
    json(conn, %{data: %{message: "Sessão encerrada no cliente; tokens JWT são sem estado."}})
  end

  def renew(conn, _params) do
    user = current_resource(conn)

    case Tokens.issue_pair(user) do
      {:ok, access, renewal} ->
        json(conn, %{
          data: %{access_token: access, renewal_token: renewal}
        })

      {:error, _} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{
          error: %{
            code: "token_erro",
            message: "Não foi possível renovar a sessão."
          }
        })
    end
  end
end
