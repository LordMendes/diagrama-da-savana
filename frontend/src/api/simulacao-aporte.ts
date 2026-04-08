import { apiRequest } from "@/lib/api";
import type { AporteRow } from "@/api/carteira";

export type MacroLayerRow = {
  macro_class: string;
  amount: string;
  shortfall_value: string;
};

export type MicroAllocationRow = {
  holding_id: string;
  asset_id: string;
  ticker: string;
  macro_class: string;
  resistance_score: number;
  unit_price: string;
  shares: number;
  amount_brl: string;
};

export type SimulacaoResult = {
  amount: string;
  portfolio_value_before: string;
  macro_layers: MacroLayerRow[];
  micro_allocations: MicroAllocationRow[];
  warnings: string[];
  unallocated_amount: string;
  quotes_partial: boolean;
};

export async function postSimulacaoAporte(
  portfolioId: string,
  amount: string,
  token: string,
) {
  return apiRequest<{ data: SimulacaoResult }>(
    `/api/v1/portfolios/${portfolioId}/simulacao_aporte`,
    {
      method: "POST",
      token,
      json: { simulacao_aporte: { amount } },
    },
  );
}

export type AplicarSimulacaoResponse = {
  simulacao: SimulacaoResult;
  aporte: AporteRow;
};

export async function postAplicarSimulacaoAporte(
  portfolioId: string,
  amount: string,
  token: string,
) {
  return apiRequest<{ data: AplicarSimulacaoResponse }>(
    `/api/v1/portfolios/${portfolioId}/simulacao_aporte/aplicar`,
    {
      method: "POST",
      token,
      json: { simulacao_aporte: { amount } },
    },
  );
}
