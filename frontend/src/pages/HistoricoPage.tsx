import { useQuery } from "@tanstack/react-query";
import { useMemo, useState } from "react";
import { useAuth } from "@/auth/auth-context";
import { fetchAportes, fetchPortfolios, type AporteRow } from "@/api/carteira";
import { ApiError } from "@/lib/api";
import { formatBrl } from "@/lib/format-brl";
import {
  classifyAporteNote,
  type HistoricoFiltroOrigem,
} from "@/lib/historico-aporte";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Label } from "@/components/ui/label";
import { PageError, PageLoading } from "@/components/layout/PageStatus";

function formatDate(iso: string) {
  try {
    const d = new Date(iso + (iso.includes("T") ? "" : "T12:00:00"));
    return d.toLocaleDateString("pt-BR");
  } catch {
    return iso;
  }
}

function originLabel(origin: ReturnType<typeof classifyAporteNote>) {
  return origin === "calculadora"
    ? "Rebalanceamento (calculadora)"
    : "Aporte / registro manual";
}

function filterRows(
  rows: AporteRow[],
  origem: HistoricoFiltroOrigem,
): AporteRow[] {
  if (origem === "todos") return rows;
  return rows.filter((r) => classifyAporteNote(r.note) === origem);
}

export function HistoricoPage() {
  const { getAccessToken } = useAuth();
  const token = getAccessToken();

  const portfoliosQ = useQuery({
    queryKey: ["portfolios"],
    queryFn: () => {
      const t = getAccessToken();
      if (!t) throw new Error("Sessão inválida");
      return fetchPortfolios(t);
    },
    enabled: !!token,
  });

  const portfolioId = portfoliosQ.data?.data[0]?.id ?? null;

  const aportesQ = useQuery({
    queryKey: ["aportes", portfolioId],
    queryFn: () => fetchAportes(portfolioId!, getAccessToken()!),
    enabled: !!portfolioId && !!token,
  });

  const [origem, setOrigem] = useState<HistoricoFiltroOrigem>("todos");

  const rows = useMemo(
    () => filterRows(aportesQ.data?.data ?? [], origem),
    [aportesQ.data?.data, origem],
  );

  const errMsg =
    portfoliosQ.error instanceof ApiError
      ? portfoliosQ.error.message
      : aportesQ.error instanceof ApiError
        ? aportesQ.error.message
        : null;

  if (portfoliosQ.isLoading || (portfolioId && aportesQ.isLoading)) {
    return <PageLoading title="Histórico" variant="simple" />;
  }

  if (portfoliosQ.isError || aportesQ.isError) {
    return (
      <PageError
        title="Histórico"
        message={errMsg ?? "Não foi possível carregar o histórico."}
      />
    );
  }

  if (!portfolioId) {
    return (
      <div className="flex flex-1 flex-col gap-4">
        <h1 className="text-2xl font-semibold tracking-tight">Histórico</h1>
        <p className="text-sm text-muted-foreground">
          Crie uma carteira em Carteira para registrar aportes e simulações
          aplicadas.
        </p>
      </div>
    );
  }

  return (
    <div className="flex flex-1 flex-col gap-8">
      <div>
        <h1 className="text-2xl font-semibold tracking-tight text-foreground">
          Histórico
        </h1>
        <p className="mt-1 text-sm text-muted-foreground">
          Aportes registrados e aplicações da calculadora de rebalanceamento na
          sua carteira principal.
        </p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="text-base">Filtro</CardTitle>
        </CardHeader>
        <CardContent className="max-w-md space-y-2">
          <Label htmlFor="hist-origem">Origem</Label>
          <select
            id="hist-origem"
            className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
            value={origem}
            onChange={(e) =>
              setOrigem(e.target.value as HistoricoFiltroOrigem)
            }
          >
            <option value="todos">Todos</option>
            <option value="manual">Aportes / manual</option>
            <option value="calculadora">Rebalanceamento (calculadora)</option>
          </select>
        </CardContent>
      </Card>

      <div className="overflow-x-auto rounded-xl border border-border/80 bg-card shadow-sm">
        <table className="w-full min-w-[36rem] border-collapse text-sm">
          <thead>
            <tr className="border-b border-border bg-muted/40 text-left">
              <th className="px-4 py-3 font-medium">Data</th>
              <th className="px-4 py-3 font-medium">Valor</th>
              <th className="px-4 py-3 font-medium">Origem</th>
              <th className="px-4 py-3 font-medium">Observação</th>
            </tr>
          </thead>
          <tbody>
            {rows.length === 0 ? (
              <tr>
                <td
                  colSpan={4}
                  className="px-4 py-8 text-center text-muted-foreground"
                >
                  Nenhum registro para esse filtro.
                </td>
              </tr>
            ) : (
              rows.map((r) => {
                const o = classifyAporteNote(r.note);
                return (
                  <tr
                    key={r.id}
                    className="border-b border-border/60 last:border-0"
                  >
                    <td className="px-4 py-3 whitespace-nowrap">
                      {formatDate(r.occurred_on)}
                    </td>
                    <td className="px-4 py-3 tabular-nums font-medium">
                      {formatBrl(r.amount)}
                    </td>
                    <td className="px-4 py-3">{originLabel(o)}</td>
                    <td className="max-w-[14rem] truncate px-4 py-3 text-muted-foreground">
                      {r.note?.trim() ? r.note : "—"}
                    </td>
                  </tr>
                );
              })
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
