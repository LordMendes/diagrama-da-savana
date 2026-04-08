defmodule DiagramaSavanaWeb.API.V1.PasswordResetController do
  use DiagramaSavanaWeb, :api

  alias DiagramaSavana.Accounts
  alias DiagramaSavanaWeb.ApiJSON

  @doc """
  Solicita e-mail de redefinição (resposta genérica contra enumeração).
  """
  def create(conn, %{"email" => email}) when is_binary(email) do
    :ok = Accounts.deliver_password_reset_instructions(email)

    conn
    |> put_status(:ok)
    |> json(%{
      data: %{
        message:
          "Se o e-mail estiver cadastrado, você receberá instruções para redefinir a senha."
      }
    })
  end

  def create(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{
      error: %{
        code: "corpo_invalido",
        message: "Envie o campo \"email\"."
      }
    })
  end

  @doc """
  Confirma nova senha com token opaco recebido por e-mail.
  """
  def update(conn, %{"token" => token, "password" => _, "password_confirmation" => _} = params)
      when is_binary(token) do
    case Accounts.reset_password_with_token(
           token,
           Map.take(params, ["password", "password_confirmation"])
         ) do
      {:ok, _user} ->
        json(conn, %{data: %{message: "Senha atualizada com sucesso."}})

      {:error, :invalid_or_expired_token} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          error: %{
            code: "token_invalido",
            message: "Token inválido ou expirado. Solicite uma nova redefinição de senha."
          }
        })

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          error: %{
            code: "validacao_falhou",
            message: "Não foi possível atualizar a senha.",
            fields: ApiJSON.changeset_errors(changeset)
          }
        })
    end
  end

  def update(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{
      error: %{
        code: "corpo_invalido",
        message: "Envie token, password e password_confirmation."
      }
    })
  end
end
