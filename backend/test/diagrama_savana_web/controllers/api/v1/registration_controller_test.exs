defmodule DiagramaSavanaWeb.API.V1.RegistrationControllerTest do
  use DiagramaSavanaWeb.ConnCase, async: true

  @password "senha_segura_8"

  describe "POST /api/v1/registration" do
    test "cria usuário e retorna tokens", %{conn: conn} do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post(
          "/api/v1/registration",
          Jason.encode!(%{
            "user" => %{
              "email" => "novo@example.com",
              "password" => @password,
              "password_confirmation" => @password
            }
          })
        )

      assert %{"data" => %{"access_token" => at, "renewal_token" => rt, "user" => u}} =
               json_response(conn, 201)

      assert is_binary(at) and is_binary(rt)
      assert u["email"] == "novo@example.com"
    end

    test "validação com dados inválidos", %{conn: conn} do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post(
          "/api/v1/registration",
          Jason.encode!(%{
            "user" => %{
              "email" => "invalido",
              "password" => @password,
              "password_confirmation" => "outra"
            }
          })
        )

      assert %{"error" => %{"code" => "validacao_falhou"}} = json_response(conn, 422)
    end
  end
end
