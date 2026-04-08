defmodule DiagramaSavanaWeb.API.V1.ResistanceProfileControllerTest do
  use DiagramaSavanaWeb.ConnCase, async: true

  alias DiagramaSavana.Accounts
  alias DiagramaSavana.Ativos

  @password "senha_segura_8"

  setup do
    {:ok, user} =
      Accounts.register_user(%{
        "email" => "api.resistance@example.com",
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

    {:ok, asset} = Ativos.create_asset(%{ticker: "APIR4", kind: :acao})

    {:ok, conn: build_conn(), token: access, asset: asset}
  end

  describe "GET /api/v1/resistance_criteria" do
    test "lista critérios de ações", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer " <> token)
        |> get("/api/v1/resistance_criteria?kind=acao")

      assert %{"data" => rows} = json_response(conn, 200)
      assert length(rows) == 12
      assert Enum.any?(rows, &(&1["id"] == "perenidade_negocio"))
    end
  end

  describe "PUT /api/v1/resistance_profiles/:asset_id" do
    test "cria perfil com critérios", %{conn: conn, token: token, asset: asset} do
      body = %{
        "resistance_profile" => %{
          "criteria" => %{
            "perenidade_negocio" => 1,
            "governanca" => 1
          }
        }
      }

      conn =
        conn
        |> put_req_header("authorization", "Bearer " <> token)
        |> put_req_header("content-type", "application/json")
        |> put("/api/v1/resistance_profiles/#{asset.id}", Jason.encode!(body))

      assert %{
               "data" => %{
                 "computed_score" => 2,
                 "eligible_for_allocation" => true,
                 "criteria" => crit
               }
             } = json_response(conn, 200)

      assert crit["perenidade_negocio"] == 1
      assert crit["governanca"] == 1
      assert map_size(crit) == 12
    end
  end
end
