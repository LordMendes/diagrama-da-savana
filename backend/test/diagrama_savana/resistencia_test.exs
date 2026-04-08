defmodule DiagramaSavana.ResistenciaTest do
  use DiagramaSavana.DataCase, async: true

  alias DiagramaSavana.Accounts
  alias DiagramaSavana.Ativos
  alias DiagramaSavana.Ativos.Asset
  alias DiagramaSavana.Repo
  alias DiagramaSavana.Resistencia
  alias DiagramaSavana.Resistencia.Profile

  @password "senha_segura_8"

  setup do
    {:ok, user} =
      Accounts.register_user(%{
        "email" => "resistencia.context@example.com",
        "password" => @password,
        "password_confirmation" => @password
      })

    {:ok, %Asset{} = asset} =
      Ativos.create_asset(%{ticker: "TSTE4", kind: :acao})

    {:ok, %Asset{} = asset_cripto} =
      Ativos.create_asset(%{ticker: "TSTBTC", kind: :cripto})

    {:ok, user: user, asset: asset, asset_cripto: asset_cripto}
  end

  describe "upsert_profile/3 e elegibilidade" do
    test "persiste nota e critérios", %{user: user, asset: asset} do
      crit = %{"perenidade_negocio" => 1, "governanca" => 1}

      assert {:ok, %Profile{} = p} =
               Resistencia.upsert_profile(user, asset, %{"criteria" => crit})

      p = Repo.preload(p, :asset)
      assert p.computed_score == 2
      assert p.criteria_stub["perenidade_negocio"] == 1
      assert map_size(p.criteria_stub) == 12
      assert Resistencia.eligible_for_allocation?(p)
    end

    test "nota ≤ 0 não é elegível", %{user: user, asset: asset} do
      crit = Map.new(DiagramaSavana.Resistencia.Criteria.ids(:acao), fn id -> {id, -1} end)

      assert {:ok, %Profile{} = p} =
               Resistencia.upsert_profile(user, asset, %{"criteria" => crit})

      refute Resistencia.eligible_for_allocation?(p)
      assert p.computed_score == -5
    end

    test "eligible_asset_ids_for_user/1", %{user: user, asset: asset} do
      assert {:ok, _} =
               Resistencia.upsert_profile(
                 user,
                 asset,
                 %{"criteria" => %{"perenidade_negocio" => 1}}
               )

      ids = Resistencia.eligible_asset_ids_for_user(user.id)
      assert asset.id in ids
    end

    test "persiste nota para cripto com critérios próprios", %{
      user: user,
      asset_cripto: asset_cripto
    } do
      crit = %{"adopcao_ecossistema" => 1, "tokenomics" => 1}

      assert {:ok, %Profile{} = p} =
               Resistencia.upsert_profile(user, asset_cripto, %{"criteria" => crit})

      assert p.computed_score == 2
      assert map_size(p.criteria_stub) == 12
      assert Resistencia.eligible_for_allocation?(p)
    end
  end
end
