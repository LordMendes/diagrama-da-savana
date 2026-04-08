defmodule DiagramaSavanaWeb.API.V1.MarketControllerTest do
  use DiagramaSavanaWeb.ConnCase, async: false

  import Mox

  alias DiagramaSavana.Accounts

  @password "senha_segura_8"

  setup :verify_on_exit!

  setup do
    DiagramaSavana.Brapi.Cache.ensure_table()

    {:ok, user} =
      Accounts.register_user(%{
        "email" => "market.api@example.com",
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

  describe "GET /api/v1/market/search" do
    test "autenticado — repassa resposta em data", %{conn: conn, token: token} do
      expect(DiagramaSavana.Brapi.TransportMock, :get, fn _, _ ->
        {:ok, %{"indexes" => [], "stocks" => ["PETR4"]}}
      end)

      conn =
        conn
        |> put_req_header("authorization", "Bearer " <> token)
        |> get("/api/v1/market/search?q=pet")

      assert %{"data" => %{"stocks" => ["PETR4"]}} = json_response(conn, 200)
    end

    test "401 sem token", %{conn: conn} do
      conn = get(conn, "/api/v1/market/search?q=x")
      assert json_response(conn, 401)
    end

    test "429 quando transport indica limite", %{conn: conn, token: token} do
      expect(DiagramaSavana.Brapi.TransportMock, :get, fn _, _ ->
        {:error, :rate_limited}
      end)

      conn =
        conn
        |> put_req_header("authorization", "Bearer " <> token)
        |> get("/api/v1/market/search?q=bb")

      assert %{"error" => %{"code" => "limite_cotacoes"}} = json_response(conn, 429)
    end
  end

  describe "GET /api/v1/market/quotes/:ticker" do
    test "cotação", %{conn: conn, token: token} do
      expect(DiagramaSavana.Brapi.TransportMock, :get, fn _, _ ->
        {:ok, %{"results" => [%{"symbol" => "PETR4"}]}}
      end)

      conn =
        conn
        |> put_req_header("authorization", "Bearer " <> token)
        |> get("/api/v1/market/quotes/petr4")

      assert %{"data" => %{"results" => _}} = json_response(conn, 200)
    end

    test "query range e interval", %{conn: conn, token: token} do
      expect(DiagramaSavana.Brapi.TransportMock, :get, fn _, params ->
        assert params[:range] == "1mo"
        assert params[:interval] == "1d"
        {:ok, %{"results" => []}}
      end)

      conn =
        conn
        |> put_req_header("authorization", "Bearer " <> token)
        |> get("/api/v1/market/quotes/PETR4?range=1mo&interval=1d")

      assert json_response(conn, 200)
    end
  end
end
