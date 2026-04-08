defmodule DiagramaSavana.Resistencia.Criteria do
  @moduledoc """
  Critérios da Nota de Resistência por grupo: **ações/ETFs**, **FIIs** ou **cripto**.

  Cada critério contribui com -1, 0 ou +1; a soma é limitada entre -5 e +10 em `DiagramaSavana.Resistencia.Scoring`.
  """

  @type group :: :acao | :fii | :cripto

  @doc """
  Grupo de checklist usado para o ativo. ETFs seguem o mesmo conjunto de ações.
  """
  @spec group_for_asset_kind(atom()) :: group() | nil
  def group_for_asset_kind(:acao), do: :acao
  def group_for_asset_kind(:etf), do: :acao
  def group_for_asset_kind(:fii), do: :fii
  def group_for_asset_kind(:cripto), do: :cripto
  def group_for_asset_kind(_), do: nil

  @doc """
  Lista `{id, label}` para API e UI (`id` estável em inglês snake_case).
  """
  @spec definitions(group()) :: [%{id: String.t(), label: String.t()}]
  def definitions(:acao) do
    [
      %{id: "perenidade_negocio", label: "Perenidade do negócio"},
      %{id: "governanca", label: "Governança e alinhamento com acionistas"},
      %{id: "dividendos_consistentes", label: "Histórico de dividendos consistente (anos)"},
      %{id: "margens_saudaveis", label: "Margens e rentabilidade sustentáveis"},
      %{id: "divida_controlada", label: "Dívida e estrutura de capital saudáveis"},
      %{id: "vantagem_competitiva", label: "Vantagem competitiva (moat) perceptível"},
      %{id: "solidez_setorial", label: "Solidez do setor frente a ciclos"},
      %{id: "transparencia_divulgacao", label: "Transparência e qualidade da divulgação"},
      %{id: "fluxo_caixa_previsivel", label: "Fluxo de caixa previsível e recorrente"},
      %{id: "risco_regulatorio", label: "Exposição regulatória gerenciável"},
      %{id: "gestao_alinhada", label: "Gestão com histórico coerente com o discurso"},
      %{id: "crescimento_sustentavel", label: "Crescimento compatível com retorno sobre capital"}
    ]
  end

  def definitions(:fii) do
    [
      %{id: "localizacao_ativo", label: "Qualidade e localização do imóvel ou portfólio"},
      %{id: "pvp_atrativo", label: "P/VP atrativo em relação aos pares"},
      %{id: "yield_relativo", label: "Rendimento (yield) competitivo vs. média de referência"},
      %{id: "diversificacao_inquilinos", label: "Diversificação de inquilinos e setores"},
      %{id: "tempo_mercado", label: "Histórico e tempo de mercado do fundo"},
      %{id: "trac_gestora", label: "Trajetória e reputação da gestora"},
      %{id: "taxa_administracao", label: "Taxa de administração razoável para a estratégia"},
      %{id: "vacancia_controlada", label: "Vacância e inadimplência controladas"},
      %{id: "reajuste_aluguel", label: "Indexação e reajuste de aluguéis"},
      %{id: "liquidez_negociacao", label: "Liquidez das cotas na bolsa"},
      %{id: "qualidade_inquilinos", label: "Qualidade e solidez dos principais inquilinos"},
      %{id: "documentacao_regulatoria", label: "Documentação e compliance (CVM) em dia"}
    ]
  end

  def definitions(:cripto) do
    [
      %{id: "adopcao_ecossistema", label: "Adoção, utilidade e ecossistema reais"},
      %{id: "seguranca_historico", label: "Segurança da rede e histórico de incidentes"},
      %{id: "descentralizacao", label: "Descentralização (validação, concentração)"},
      %{id: "liquidez_negociacao", label: "Liquidez e profundidade em mercados"},
      %{id: "transparencia_governanca", label: "Transparência e governança do projeto"},
      %{id: "tokenomics", label: "Tokenomics sustentável (emissão, utilidade, bloqueios)"},
      %{id: "risco_regulatorio", label: "Risco regulatório e compliance gerenciáveis"},
      %{id: "tecnologia_madurez", label: "Tecnologia auditada ou com histórico sólido"},
      %{id: "moat_competitivo", label: "Diferenciação frente a competidores (vantagem)"},
      %{id: "comunidade_desenvolvimento", label: "Comunidade e desenvolvimento ativo"},
      %{id: "custodia_opcoes", label: "Custódia e autocustódia viáveis"},
      %{id: "volatilidade_aceitavel", label: "Volatilidade e risco alinhados ao seu objetivo"}
    ]
  end

  @doc false
  def ids(group) when group in [:acao, :fii, :cripto] do
    group |> definitions() |> Enum.map(& &1.id)
  end

  @doc false
  def group_for_query_param("acao"), do: {:ok, :acao}
  def group_for_query_param("fii"), do: {:ok, :fii}
  def group_for_query_param("cripto"), do: {:ok, :cripto}
  def group_for_query_param(_), do: {:error, :invalid_kind}
end
