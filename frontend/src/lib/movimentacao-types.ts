/** Linha normalizada exportada de planilhas de movimentação (ex.: BTG). */
export type MovimentacaoRow = {
  entradaSaida: "Credito" | "Debito" | string;
  data: string;
  movimentacao: string;
  produto: string;
  quantidade: number;
  /** Preço unitário quando aplicável; linhas internas podem usar "-". */
  precoUnitario: number | null;
  /** Valor da operação em BRL quando aplicável. */
  valorOperacao: number | null;
};

export type AtivoPrecoMedioResult = {
  ticker: string;
  /** Nome completo do produto (primeira ocorrência na planilha). */
  produtoLabel: string;
  /** Quantidade líquida após processar as linhas (compras − vendas e transferências). */
  quantidade: number;
  /** Custo contábil remanescente (base para preço médio). */
  custoTotal: number;
  /** Preço médio = custoTotal / quantidade quando quantidade > 0. */
  precoMedio: number | null;
};

export type MovimentacaoPrecoMedioReport = {
  ativos: AtivoPrecoMedioResult[];
  /** Avisos não fatais (linhas ignoradas, arredondamentos, etc.). */
  avisos: string[];
};
