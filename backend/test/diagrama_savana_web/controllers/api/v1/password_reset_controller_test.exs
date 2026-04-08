defmodule DiagramaSavanaWeb.API.V1.PasswordResetControllerTest do
  use DiagramaSavanaWeb.ConnCase, async: false

  import Swoosh.TestAssertions

  alias DiagramaSavana.Accounts

  setup :set_swoosh_global

  @password "senha_segura_8"

  setup do
    {:ok, _user} =
      Accounts.register_user(%{
        "email" => "reset@example.com",
        "password" => @password,
        "password_confirmation" => @password
      })

    :ok
  end

  describe "POST /api/v1/password-reset" do
    test "resposta genérica e e-mail enfileirado", %{conn: conn} do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post(
          "/api/v1/password-reset",
          Jason.encode!(%{"email" => "reset@example.com"})
        )

      assert %{"data" => %{"message" => _}} = json_response(conn, 200)
      assert_email_sent(subject: "Redefinição de senha — Diagrama da Savana")
    end
  end

  describe "PUT /api/v1/password-reset" do
    test "token inválido retorna erro mapeável", %{conn: conn} do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> put(
          "/api/v1/password-reset",
          Jason.encode!(%{
            "token" => "00000000-0000-0000-0000-000000000000",
            "password" => "nova_senha_8",
            "password_confirmation" => "nova_senha_8"
          })
        )

      assert %{"error" => %{"code" => "token_invalido"}} = json_response(conn, 422)
    end
  end
end
