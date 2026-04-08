defmodule DiagramaSavanaWeb.API.V1.SimulacaoAporteControllerTest do
  use DiagramaSavanaWeb.ConnCase, async: true

  alias DiagramaSavana.Accounts

  @password "senha_segura_8"

  setup do
    {:ok, user} =
      Accounts.register_user(%{
        "email" => "api.simulacao@example.com",
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

  describe "POST /api/v1/portfolios/:id/simulacao_aporte" do
    test "carteira vazia: retorna camadas e valor não alocado", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer " <> token)
        |> get("/api/v1/portfolios")

      assert %{"data" => [%{"id" => pid} | _]} = json_response(conn, 200)

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer " <> token)
        |> put_req_header("content-type", "application/json")
        |> post(
          "/api/v1/portfolios/#{pid}/simulacao_aporte",
          Jason.encode!(%{"simulacao_aporte" => %{"amount" => "2500.50"}})
        )

      assert %{
               "data" => %{
                 "amount" => "2500.50",
                 "unallocated_amount" => "2500.50",
                 "macro_layers" => layers,
                 "micro_allocations" => [],
                 "warnings" => [],
                 "quotes_partial" => false
               }
             } = json_response(conn, 200)

      assert length(layers) == 6
    end

    test "valor inválido", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer " <> token)
        |> get("/api/v1/portfolios")

      assert %{"data" => [%{"id" => pid} | _]} = json_response(conn, 200)

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer " <> token)
        |> put_req_header("content-type", "application/json")
        |> post(
          "/api/v1/portfolios/#{pid}/simulacao_aporte",
          Jason.encode!(%{"simulacao_aporte" => %{"amount" => "abc"}})
        )

      assert %{"error" => %{"code" => "entrada_invalida"}} = json_response(conn, 422)
    end
  end
end
