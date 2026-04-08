defmodule DiagramaSavana.Resistencia.ScoringTest do
  use ExUnit.Case, async: true

  alias DiagramaSavana.Ativos.Asset
  alias DiagramaSavana.Resistencia.Scoring

  describe "clamp/1" do
    test "mantém valores dentro da faixa" do
      assert Scoring.clamp(0) == 0
      assert Scoring.clamp(10) == 10
      assert Scoring.clamp(-5) == -5
    end

    test "limita extremos" do
      assert Scoring.clamp(100) == 10
      assert Scoring.clamp(-100) == -5
    end
  end

  describe "build_for_upsert/2" do
    test "soma e aplica limite para ação" do
      asset = %Asset{id: Ecto.UUID.generate(), kind: :acao, ticker: "PETR4"}

      crit =
        Map.new(
          [
            "perenidade_negocio",
            "governanca",
            "dividendos_consistentes",
            "margens_saudaveis",
            "divida_controlada",
            "vantagem_competitiva",
            "solidez_setorial",
            "transparencia_divulgacao",
            "fluxo_caixa_previsivel",
            "risco_regulatorio",
            "gestao_alinhada",
            "crescimento_sustentavel"
          ],
          fn id -> {id, 1} end
        )

      assert {:ok, %{computed_score: 10, criteria_stub: stored}} =
               Scoring.build_for_upsert(asset, crit)

      assert map_size(stored) == 12
      assert stored["perenidade_negocio"] == 1
    end

    test "piso -5 quando a soma é muito negativa" do
      asset = %Asset{id: Ecto.UUID.generate(), kind: :fii, ticker: "KNRI11"}

      crit =
        Map.new(
          [
            "localizacao_ativo",
            "pvp_atrativo",
            "yield_relativo",
            "diversificacao_inquilinos",
            "tempo_mercado",
            "trac_gestora",
            "taxa_administracao",
            "vacancia_controlada",
            "reajuste_aluguel",
            "liquidez_negociacao",
            "qualidade_inquilinos",
            "documentacao_regulatoria"
          ],
          fn id -> {id, -1} end
        )

      assert {:ok, %{computed_score: -5}} = Scoring.build_for_upsert(asset, crit)
    end

    test "rejeita chave desconhecida" do
      asset = %Asset{id: Ecto.UUID.generate(), kind: :acao, ticker: "X"}

      assert {:error, {:unknown_criteria, ["extra"]}} =
               Scoring.build_for_upsert(asset, %{"extra" => 1})
    end

    test "soma e aplica limite para cripto" do
      asset = %Asset{id: Ecto.UUID.generate(), kind: :cripto, ticker: "BTC"}

      crit =
        Map.new(DiagramaSavana.Resistencia.Criteria.ids(:cripto), fn id -> {id, 1} end)

      assert {:ok, %{computed_score: 10, criteria_stub: stored}} =
               Scoring.build_for_upsert(asset, crit)

      assert map_size(stored) == 12
      assert stored["adopcao_ecossistema"] == 1
    end

    test "rejeita tipo de ativo sem checklist" do
      asset = %Asset{id: Ecto.UUID.generate(), kind: :renda_fixa, ticker: "SELIC"}

      assert {:error, :unsupported_kind} = Scoring.build_for_upsert(asset, %{})
    end

    test "rejeita valor fora de -1, 0, 1" do
      asset = %Asset{id: Ecto.UUID.generate(), kind: :acao, ticker: "Y"}

      crit = %{"perenidade_negocio" => 2}

      assert {:error, {:invalid_values, ["perenidade_negocio"]}} =
               Scoring.build_for_upsert(asset, crit)
    end
  end
end
