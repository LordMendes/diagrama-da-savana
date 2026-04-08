import { useQuery } from "@tanstack/react-query";
import { Link } from "react-router-dom";
import { useAuth } from "@/auth/auth-context";
import {
  fetchPortfolios,
  fetchPortfolioSummary,
} from "@/api/carteira";
import { formatBrl, formatPercent } from "@/lib/format-brl";
import { ApiError } from "@/lib/api";
import { PageError, PageLoading } from "@/components/layout/PageStatus";

const MACRO_LABELS: Record<string, string> = {
  renda_fixa: "Renda fixa",
  renda_variavel: "Renda variável",
  fiis: "FIIs",
  internacional: "Internacional",
  cripto: "Cripto",
  outros: "Outros",
};

const MACRO_COLORS: Record<string, string> = {
  renda_fixa: "bg-emerald-600",
  renda_variavel: "bg-primary",
  fiis: "bg-amber-600/90",
  internacional: "bg-sky-600/90",
  cripto: "bg-violet-600/90",
  outros: "bg-stone-500/80",
};

export function DashboardPage() {
  const { getAccessToken } = useAuth();
  const token = getAccessToken();

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

  const summaryQ = useQuery({
    queryKey: ["portfolio-summary", portfolioId],
    queryFn: async () => {
      const t = getAccessToken();
      if (!t || !portfolioId) throw new Error("Não autenticado");
      return fetchPortfolioSummary(portfolioId, t);
    },
    enabled: !!token && !!portfolioId,
  });

  const summary = summaryQ.data?.data;
  const errMsg =
    portfoliosQ.error instanceof ApiError
      ? portfoliosQ.error.message
      : summaryQ.error instanceof ApiError
        ? summaryQ.error.message
        : null;

  if (portfoliosQ.isLoading || (portfolioId && summaryQ.isLoading)) {
    return <PageLoading title="Painel" />;
  }

  if (portfoliosQ.isError || summaryQ.isError) {
    return (
      <PageError
        title="Painel"
        message={
          errMsg ?? "Não foi possível carregar o painel. Tente novamente."
        }
      />
    );
  }

  if (!summary) {
    return (
      <div className="flex flex-1 flex-col gap-4">
        <h1 className="text-2xl font-semibold tracking-tight">Painel</h1>
        <p className="text-sm text-muted-foreground">
          Nenhuma carteira encontrada. Acesse Carteira para configurar metas e
          posições.
        </p>
      </div>
    );
  }

  const daily = summary.daily_change_percent;
  const dailyNum =
    daily !== null && daily !== undefined ? Number(daily.replace(",", ".")) : NaN;
  const dailyPositive = !Number.isNaN(dailyNum) && dailyNum >= 0;

  return (
    <div className="flex flex-1 flex-col gap-8">
      <div>
        <h1 className="text-2xl font-semibold tracking-tight text-foreground">
          Painel
        </h1>
        <p className="mt-1 text-sm text-muted-foreground">
          Visão geral da carteira <strong>{summary.portfolio.name}</strong> com
          cotações da brapi e metas por classe.
        </p>
      </div>

      <section className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        <article className="rounded-xl border border-border/80 bg-card p-5 shadow-sm">
          <h2 className="text-sm font-medium text-muted-foreground">
            Valor total
          </h2>
          <p className="mt-2 text-2xl font-semibold tabular-nums text-foreground">
            {formatBrl(summary.total_value)}
          </p>
          <p
            className={
              daily === null || daily === undefined
                ? "mt-1 text-sm text-muted-foreground"
                : dailyPositive
                  ? "mt-1 text-sm text-emerald-700"
                  : "mt-1 text-sm text-rose-700"
            }
          >
            Variação do dia:{" "}
            {daily !== null && daily !== undefined
              ? formatPercent(Number(daily.replace(",", ".")))
              : "—"}
            {summary.quotes_partial ? (
              <span className="ml-1 text-xs text-muted-foreground">
                (parcial)
              </span>
            ) : null}
          </p>
        </article>

        <article className="rounded-xl border border-border/80 bg-card p-5 shadow-sm sm:col-span-2 lg:col-span-2">
          <h2 className="text-sm font-medium text-muted-foreground">
            Alocação atual por classe
          </h2>
          <div className="mt-4 flex flex-col gap-4">
            <div
              className="flex h-4 w-full max-w-md overflow-hidden rounded-full bg-muted"
              role="img"
              aria-label="Distribuição por classe"
            >
              {(() => {
                const parts = summary.allocation_by_macro
                  .map((row) => ({
                    macro: row.macro_class,
                    pct: Number(String(row.current_percent).replace(",", ".")),
                  }))
                  .filter((x) => !Number.isNaN(x.pct) && x.pct > 0);
                const sum = parts.reduce((a, b) => a + b.pct, 0) || 1;
                return parts.map((x) => (
                  <div
                    key={x.macro}
                    className={`h-full min-w-px ${MACRO_COLORS[x.macro] ?? "bg-muted"}`}
                    style={{ flex: `${x.pct / sum} 1 0%` }}
                  />
                ));
              })()}
            </div>
            <ul className="min-w-0 flex-1 space-y-2">
              {summary.allocation_by_macro.map((row) => (
                <li
                  key={row.macro_class}
                  className="flex items-center justify-between gap-2 text-sm"
                >
                  <span className="flex min-w-0 items-center gap-2">
                    <span
                      className={`size-2.5 shrink-0 rounded-sm ${MACRO_COLORS[row.macro_class] ?? "bg-muted"}`}
                    />
                    <span className="truncate">
                      {MACRO_LABELS[row.macro_class] ?? row.macro_class}
                    </span>
                  </span>
                  <span className="tabular-nums text-muted-foreground">
                    {row.current_percent.replace(".", ",")}%
                  </span>
                </li>
              ))}
            </ul>
          </div>
        </article>
      </section>

      <section className="rounded-xl border border-border/80 bg-card shadow-sm">
        <div className="border-b border-border/60 px-5 py-4">
          <h2 className="text-sm font-semibold text-foreground">
            Aportes recentes
          </h2>
          <p className="text-xs text-muted-foreground">
            Registre novos aportes em Carteira.
          </p>
        </div>
        <div className="overflow-x-auto">
          {summary.recent_aportes.length === 0 ? (
            <p className="px-5 py-6 text-sm text-muted-foreground">
              Nenhum aporte registrado ainda.
            </p>
          ) : (
            <table className="w-full min-w-[28rem] text-left text-sm">
              <thead>
                <tr className="border-b border-border/60 bg-muted/40 text-muted-foreground">
                  <th className="px-5 py-3 font-medium">Data</th>
                  <th className="px-5 py-3 font-medium">Valor</th>
                  <th className="px-5 py-3 font-medium">Observação</th>
                </tr>
              </thead>
              <tbody>
                {summary.recent_aportes.map((row) => (
                  <tr
                    key={row.id}
                    className="border-b border-border/40 last:border-0"
                  >
                    <td className="px-5 py-3 tabular-nums text-muted-foreground">
                      {formatDatePt(row.occurred_on)}
                    </td>
                    <td className="px-5 py-3 tabular-nums">
                      {formatBrl(row.amount)}
                    </td>
                    <td className="px-5 py-3 text-muted-foreground">
                      {row.note ?? "—"}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      </section>

      <aside className="rounded-lg border border-dashed border-primary/30 bg-primary/5 px-4 py-3 text-sm text-muted-foreground">
        <strong className="font-medium text-foreground">Próximo aporte</strong>
        :{" "}
        <Link
          className="font-medium text-primary underline-offset-4 hover:underline"
          to="/app/calculadora"
        >
          Utilize a calculadora de aporte
        </Link>{" "}
        para simular e aplicar no portfólio.
      </aside>
    </div>
  );
}

function formatDatePt(iso: string) {
  const [y, m, d] = iso.split("-").map(Number);
  if (!y || !m || !d) return iso;
  return `${String(d).padStart(2, "0")}/${String(m).padStart(2, "0")}/${y}`;
}
