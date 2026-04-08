defmodule DiagramaSavanaWeb.API.V1.PortfolioControllerTest do
  use DiagramaSavanaWeb.ConnCase, async: true

  alias DiagramaSavana.Accounts

  @password "senha_segura_8"

  setup do
    {:ok, user} =
      Accounts.register_user(%{
        "email" => "api.portfolio@example.com",
        "password" => @password,
        "password_confirmation" => @password
      })

    conn =
      build_conn()
      |> put_req_header("content-type", "application/json")
      |> post(
        "/api/v1/session",
        Jason.encode!(%{"user" => %{"email" => user.email, "password" => @password}})
      )

    %{"data" => %{"access_token" => access}} = json_response(conn, 200)

    {:ok, conn: build_conn(), token: access}
  end

  describe "GET /api/v1/portfolios" do
    test "lista carteiras autenticado", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer " <> token)
        |> get("/api/v1/portfolios")

      assert %{"data" => portfolios} = json_response(conn, 200)
      assert Enum.any?(portfolios, &(&1["name"] == "Principal"))
    end

    test "401 sem token", %{conn: conn} do
      conn = get(conn, "/api/v1/portfolios")
      assert json_response(conn, 401)
    end
  end

  describe "POST /api/v1/portfolios" do
    test "cria carteira", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer " <> token)
        |> put_req_header("content-type", "application/json")
        |> post(
          "/api/v1/portfolios",
          Jason.encode!(%{"portfolio" => %{"name" => "Reserva"}})
        )

      assert %{"data" => %{"id" => _, "name" => "Reserva"}} = json_response(conn, 201)
    end
  end

  describe "GET /api/v1/portfolios/:id/summary" do
    test "resumo com carteira vazia", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer " <> token)
        |> get("/api/v1/portfolios")

      assert %{"data" => [%{"id" => pid} | _]} = json_response(conn, 200)

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer " <> token)
        |> get("/api/v1/portfolios/#{pid}/summary")

      assert %{
               "data" => %{
                 "total_value" => "0",
                 "quotes_partial" => false,
                 "allocation_by_macro" => rows,
                 "recent_aportes" => []
               }
             } = json_response(conn, 200)

      assert length(rows) == 6
    end
  end
end
