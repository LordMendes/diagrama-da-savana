import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useState } from "react";
import { useAuth } from "@/auth/auth-context";
import { fetchPortfolios } from "@/api/carteira";
import {
  postAplicarSimulacaoAporte,
  postSimulacaoAporte,
  type SimulacaoResult,
} from "@/api/simulacao-aporte";
import { ApiError } from "@/lib/api";
import { formatBrl } from "@/lib/format-brl";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { PageError, PageLoading } from "@/components/layout/PageStatus";

const MACRO_LABELS: Record<string, string> = {
  renda_fixa: "Renda fixa",
  renda_variavel: "Renda variável",
  fiis: "FIIs",
  internacional: "Internacional",
  cripto: "Cripto",
  outros: "Outros",
};

function parseAmountInput(raw: string): string | null {
  const s = raw.trim().replace(/\s/g, "");
  if (!s) return null;
  const hasComma = s.includes(",");
  const hasDot = s.includes(".");
  let normalized: string;
  if (hasComma && hasDot) {
    normalized =
      s.lastIndexOf(",") > s.lastIndexOf(".")
        ? s.replace(/\./g, "").replace(",", ".")
        : s.replace(/,/g, "");
  } else if (hasComma) {
    normalized = s.replace(",", ".");
  } else {
    normalized = s;
  }
  const n = Number(normalized);
  if (Number.isNaN(n) || n <= 0) return null;
  return n.toFixed(2);
}

function buildRecommendationPhrase(sim: SimulacaoResult): string {
  const brl = formatBrl(sim.amount);
  const withShares = sim.micro_allocations.filter((r) => r.shares > 0);
  if (withShares.length === 0) {
    return `Com ${brl}, não há compras sugeridas com as regras atuais (metas, notas e cotações). Ajuste metas em Carteira ou notas em Nota de resistência.`;
  }
  const totalAlloc = withShares.reduce(
    (acc, r) => acc + Number(String(r.amount_brl).replace(",", ".")),
    0,
  );
  const parts = withShares.map(
    (r) =>
      `${r.shares} ${r.shares === 1 ? "cota" : "cotas"} de ${r.ticker}`,
  );
  return `Com ${brl}, aloque cerca de ${formatBrl(totalAlloc)}: ${parts.join("; ")}.`;
}

export function CalculadoraAportePage() {
  const { getAccessToken } = useAuth();
  const token = getAccessToken();
  const queryClient = useQueryClient();
  const [amountRaw, setAmountRaw] = useState("");
  const [lastSim, setLastSim] = useState<SimulacaoResult | null>(null);
  const [applyOk, setApplyOk] = useState<string | null>(null);

  const portfoliosQ = useQuery({
    queryKey: ["portfolios"],
    queryFn: async () => {
      const t = getAccessToken();
      if (!t) throw new Error("Não autenticado");
      return fetchPortfolios(t);
    },
    enabled: !!token,
  });

  const portfolioId = portfoliosQ.data?.data[0]?.id;

  const simMutation = useMutation({
    mutationFn: async () => {
      const t = getAccessToken();
      if (!t || !portfolioId) throw new Error("Sessão ou carteira inválida");
      const normalized = parseAmountInput(amountRaw);
      if (!normalized) throw new Error("VALOR_INVALIDO");
      return postSimulacaoAporte(portfolioId, normalized, t);
    },
    onSuccess: (res) => {
      setLastSim(res.data);
      setApplyOk(null);
    },
  });

  const applyMutation = useMutation({
    mutationFn: async () => {
      const t = getAccessToken();
      if (!t || !portfolioId) throw new Error("Sessão ou carteira inválida");
      const normalized = parseAmountInput(amountRaw);
      if (!normalized) throw new Error("VALOR_INVALIDO");
      return postAplicarSimulacaoAporte(portfolioId, normalized, t);
    },
    onSuccess: (res) => {
      setLastSim(res.data.simulacao);
      setApplyOk(
        `Posições atualizadas e aporte de ${formatBrl(res.data.aporte.amount)} registrado.`,
      );
      void queryClient.invalidateQueries({ queryKey: ["portfolios"] });
      void queryClient.invalidateQueries({ queryKey: ["portfolio-summary"] });
      void queryClient.invalidateQueries({
        queryKey: ["holdings", portfolioId],
      });
    },
  });

  const simErr =
    simMutation.error instanceof ApiError
      ? simMutation.error.message
      : simMutation.error instanceof Error &&
          simMutation.error.message === "VALOR_INVALIDO"
        ? "Informe um valor maior que zero (use vírgula ou ponto para centavos)."
        : simMutation.error
          ? "Não foi possível simular. Tente novamente."
          : null;

  const applyErr =
    applyMutation.error instanceof ApiError
      ? applyMutation.error.message
      : applyMutation.error instanceof Error &&
          applyMutation.error.message === "VALOR_INVALIDO"
        ? "Informe um valor maior que zero."
        : applyMutation.error
          ? "Não foi possível aplicar. Tente novamente."
          : null;

  if (portfoliosQ.isLoading) {
    return (
      <PageLoading
        title="Calculadora de aporte"
        variant="simple"
        description="Carregando carteira…"
      />
    );
  }

  if (portfoliosQ.isError) {
    const msg =
      portfoliosQ.error instanceof ApiError
        ? portfoliosQ.error.message
        : "Não foi possível carregar a carteira. Verifique a conexão e tente de novo.";
    return <PageError title="Calculadora de aporte" message={msg} />;
  }

  if (!portfolioId) {
    return (
      <div className="flex flex-col gap-2">
        <h1 className="text-2xl font-semibold tracking-tight">
          Calculadora de aporte
        </h1>
        <p className="text-sm text-muted-foreground" role="status">
          Nenhuma carteira disponível. Use a tela Carteira após o login para
          criar a carteira principal.
        </p>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-8">
      <div>
        <h1 className="text-2xl font-semibold tracking-tight text-foreground">
          Calculadora de aporte
        </h1>
        <p className="mt-1 max-w-2xl text-sm text-muted-foreground">
          Informe o valor do aporte para ver a sugestão em duas camadas: macro
          (classes em relação às metas) e micro (peso da nota de resistência e
          cotas inteiras com cotação atual).
        </p>
      </div>

      <Card className="border-border/80 p-5 shadow-sm">
        <form
          className="flex flex-col gap-4 sm:flex-row sm:flex-wrap sm:items-end"
          onSubmit={(e) => {
            e.preventDefault();
            setApplyOk(null);
            simMutation.mutate();
          }}
        >
          <div className="flex min-w-[12rem] flex-1 flex-col gap-2">
            <Label htmlFor="aporte-valor">Valor do aporte (R$)</Label>
            <Input
              id="aporte-valor"
              inputMode="decimal"
              autoComplete="off"
              placeholder="Ex.: 5000"
              value={amountRaw}
              onChange={(e) => setAmountRaw(e.target.value)}
            />
          </div>
          <Button
            type="submit"
            disabled={simMutation.isPending || applyMutation.isPending}
          >
            {simMutation.isPending ? "Calculando…" : "Calcular"}
          </Button>
        </form>
        {simErr ? (
          <p className="mt-3 text-sm text-destructive" role="alert">
            {simErr}
          </p>
        ) : null}
      </Card>

      {lastSim ? (
        <div className="flex flex-col gap-6">
          <Card className="border-primary/25 bg-primary/5 p-5 shadow-sm">
            <h2 className="text-sm font-semibold text-foreground">
              Recomendação
            </h2>
            <p className="mt-2 text-sm leading-relaxed text-foreground">
              {buildRecommendationPhrase(lastSim)}
            </p>
            {lastSim.quotes_partial ? (
              <p className="mt-2 text-xs text-amber-800">
                Algumas cotações não foram obtidas; o resultado pode estar
                incompleto.
              </p>
            ) : null}
          </Card>

          <section>
            <h2 className="mb-3 text-sm font-semibold text-foreground">
              Camada macro (por classe)
            </h2>
            <div className="overflow-x-auto rounded-xl border border-border/80">
              <table className="w-full min-w-[28rem] text-left text-sm">
                <thead>
                  <tr className="border-b border-border/60 bg-muted/40 text-muted-foreground">
                    <th className="px-4 py-3 font-medium">Classe</th>
                    <th className="px-4 py-3 font-medium">Valor sugerido</th>
                    <th className="px-4 py-3 font-medium">Déficit (valor)</th>
                  </tr>
                </thead>
                <tbody>
                  {lastSim.macro_layers.map((row) => (
                    <tr
                      key={row.macro_class}
                      className="border-b border-border/40 last:border-0"
                    >
                      <td className="px-4 py-3">
                        {MACRO_LABELS[row.macro_class] ?? row.macro_class}
                      </td>
                      <td className="px-4 py-3 tabular-nums">
                        {formatBrl(row.amount)}
                      </td>
                      <td className="px-4 py-3 tabular-nums text-muted-foreground">
                        {formatBrl(row.shortfall_value)}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </section>

          <section>
            <h2 className="mb-3 text-sm font-semibold text-foreground">
              Camada micro (por ativo)
            </h2>
            {lastSim.micro_allocations.length === 0 ? (
              <p className="text-sm text-muted-foreground">
                Nenhuma linha de compra. Verifique metas, notas {">"} 0 e
                posições na carteira.
              </p>
            ) : (
              <div className="overflow-x-auto rounded-xl border border-border/80">
                <table className="w-full min-w-[32rem] text-left text-sm">
                  <thead>
                    <tr className="border-b border-border/60 bg-muted/40 text-muted-foreground">
                      <th className="px-4 py-3 font-medium">Ativo</th>
                      <th className="px-4 py-3 font-medium">Classe</th>
                      <th className="px-4 py-3 font-medium">Nota</th>
                      <th className="px-4 py-3 font-medium">Cotas</th>
                      <th className="px-4 py-3 font-medium">Preço</th>
                      <th className="px-4 py-3 font-medium">Total</th>
                    </tr>
                  </thead>
                  <tbody>
                    {lastSim.micro_allocations.map((row) => (
                      <tr
                        key={`${row.holding_id}-${row.ticker}`}
                        className="border-b border-border/40 last:border-0"
                      >
                        <td className="px-4 py-3 font-medium">{row.ticker}</td>
                        <td className="px-4 py-3 text-muted-foreground">
                          {MACRO_LABELS[row.macro_class] ?? row.macro_class}
                        </td>
                        <td className="px-4 py-3 tabular-nums">
                          {row.resistance_score}
                        </td>
                        <td className="px-4 py-3 tabular-nums">{row.shares}</td>
                        <td className="px-4 py-3 tabular-nums">
                          {formatBrl(row.unit_price)}
                        </td>
                        <td className="px-4 py-3 tabular-nums">
                          {formatBrl(row.amount_brl)}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </section>

          {lastSim.warnings.length > 0 ? (
            <div
              className="rounded-lg border border-amber-500/40 bg-amber-50 px-4 py-3 text-sm text-amber-950 dark:bg-amber-950/30 dark:text-amber-100"
              role="status"
            >
              <p className="font-medium">Avisos</p>
              <ul className="mt-2 list-inside list-disc space-y-1">
                {lastSim.warnings.map((w) => (
                  <li key={w}>{w}</li>
                ))}
              </ul>
            </div>
          ) : null}

          <div className="flex flex-col gap-2 rounded-lg border border-border/80 bg-muted/20 px-4 py-3 text-sm">
            <p>
              <span className="text-muted-foreground">Não alocado: </span>
              <span className="tabular-nums font-medium">
                {formatBrl(lastSim.unallocated_amount)}
              </span>
            </p>
            <p className="text-xs text-muted-foreground">
              Inclui sobras por arredondamento de cotas inteiras ou classes sem
              ativos elegíveis.
            </p>
          </div>

          <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
            <Button
              type="button"
              variant="default"
              disabled={
                applyMutation.isPending ||
                simMutation.isPending ||
                !parseAmountInput(amountRaw)
              }
              onClick={() => {
                setApplyOk(null);
                applyMutation.mutate();
              }}
            >
              {applyMutation.isPending
                ? "Aplicando…"
                : "Aplicar no portfólio"}
            </Button>
            <p className="text-xs text-muted-foreground">
              Atualiza quantidades e preço médio das posições e registra o aporte
              no histórico.
            </p>
          </div>

          {applyErr ? (
            <p className="text-sm text-destructive" role="alert">
              {applyErr}
            </p>
          ) : null}
          {applyOk ? (
            <p
              className="rounded-lg border border-emerald-500/40 bg-emerald-50 px-4 py-3 text-sm text-emerald-950 dark:bg-emerald-950/30 dark:text-emerald-100"
              role="status"
            >
              {applyOk}
            </p>
          ) : null}
        </div>
      ) : null}
    </div>
  );
}
