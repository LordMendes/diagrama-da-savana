defmodule DiagramaSavanaWeb.API.V1.SessionControllerTest do
  use DiagramaSavanaWeb.ConnCase, async: true

  alias DiagramaSavana.Accounts

  @password "senha_segura_8"

  setup do
    {:ok, user} =
      Accounts.register_user(%{
        "email" => "login@example.com",
        "password" => @password,
        "password_confirmation" => @password
      })

    {:ok, user: user}
  end

  describe "POST /api/v1/session" do
    test "login com credenciais válidas", %{conn: conn} do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post(
          "/api/v1/session",
          Jason.encode!(%{"user" => %{"email" => "login@example.com", "password" => @password}})
        )

      assert %{"data" => %{"access_token" => _, "renewal_token" => _}} = json_response(conn, 200)
    end

    test "login com senha errada", %{conn: conn} do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post(
          "/api/v1/session",
          Jason.encode!(%{
            "user" => %{"email" => "login@example.com", "password" => "errada"}
          })
        )

      assert %{"error" => %{"code" => "credenciais_invalidas"}} = json_response(conn, 401)
    end
  end

  describe "POST /api/v1/session/renew" do
    test "renova com renewal_token válido", %{conn: conn} do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post(
          "/api/v1/session",
          Jason.encode!(%{"user" => %{"email" => "login@example.com", "password" => @password}})
        )

      %{"data" => %{"renewal_token" => renewal}} = json_response(conn, 200)

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer " <> renewal)
        |> put_req_header("content-type", "application/json")
        |> post("/api/v1/session/renew", "{}")

      assert %{"data" => %{"access_token" => _, "renewal_token" => _}} = json_response(conn, 200)
    end
  end

  describe "GET /api/v1/me" do
    test "exige Authorization", %{conn: conn} do
      conn = get(conn, "/api/v1/me")
      assert json_response(conn, 401)
    end

    test "retorna usuário com Bearer", %{conn: conn} do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post(
          "/api/v1/session",
          Jason.encode!(%{"user" => %{"email" => "login@example.com", "password" => @password}})
        )

      %{"data" => %{"access_token" => access}} = json_response(conn, 200)

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer " <> access)
        |> get("/api/v1/me")

      assert %{"data" => %{"email" => "login@example.com"}} = json_response(conn, 200)
    end
  end
end
