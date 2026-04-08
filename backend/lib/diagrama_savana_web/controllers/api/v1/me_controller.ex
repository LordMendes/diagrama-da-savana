defmodule DiagramaSavanaWeb.API.V1.MeController do
  use DiagramaSavanaWeb, :api

  import Guardian.Plug, only: [current_resource: 1]

  alias DiagramaSavana.Accounts
  alias DiagramaSavanaWeb.ApiJSON

  def show(conn, _params) do
    user = current_resource(conn)

    json(conn, %{
      data: %{
        id: user.id,
        email: user.email
      }
    })
  end

  def update(conn, params) do
    user = current_resource(conn)
    p = params["user"] || params["data"] || %{}
    email = p["email"] || p[:email]

    case Accounts.update_user_profile(user, %{email: email}) do
      {:ok, u} ->
        json(conn, %{data: %{id: u.id, email: u.email}})

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          error: %{
            code: "validacao_falhou",
            message: "Não foi possível atualizar o perfil.",
            fields: ApiJSON.changeset_errors(changeset)
          }
        })
    end
  end
end
