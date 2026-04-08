defmodule DiagramaSavanaWeb.API.V1.MeControllerTest do
  use DiagramaSavanaWeb.ConnCase, async: true

  alias DiagramaSavana.Accounts

  @password "senha_segura_8"

  setup do
    {:ok, user} =
      Accounts.register_user(%{
        "email" => "perfil@example.com",
        "password" => @password,
        "password_confirmation" => @password
      })

    {:ok, user: user}
  end

  defp authorized_conn(conn) do
    conn =
      conn
      |> put_req_header("content-type", "application/json")
      |> post(
        "/api/v1/session",
        Jason.encode!(%{"user" => %{"email" => "perfil@example.com", "password" => @password}})
      )

    %{"data" => %{"access_token" => access}} = json_response(conn, 200)

    build_conn()
    |> put_req_header("authorization", "Bearer " <> access)
    |> put_req_header("content-type", "application/json")
  end

  describe "PATCH /api/v1/me" do
    test "atualiza o e-mail", %{conn: conn} do
      conn =
        conn
        |> authorized_conn()
        |> patch(
          "/api/v1/me",
          Jason.encode!(%{"user" => %{"email" => "novo@example.com"}})
        )

      assert %{"data" => %{"email" => "novo@example.com"}} = json_response(conn, 200)
    end

    test "rejeita e-mail inválido", %{conn: conn} do
      conn =
        conn
        |> authorized_conn()
        |> patch(
          "/api/v1/me",
          Jason.encode!(%{"user" => %{"email" => "nao-e-email"}})
        )

      assert %{"error" => %{"code" => "validacao_falhou"}} = json_response(conn, 422)
    end
  end
end
