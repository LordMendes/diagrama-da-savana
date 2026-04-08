import { useQuery } from "@tanstack/react-query";
import { useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";
import { useAuth } from "@/auth/auth-context";
import { fetchAssets, type CatalogAsset } from "@/api/ativos";
import {
  searchMarketTickers,
  type MarketSearchHit,
} from "@/api/carteira";
import {
  fetchResistanceProfiles,
  type ResistanceProfileRow,
} from "@/api/resistencia";
import { ApiError } from "@/lib/api";
import { useDebouncedValue } from "@/hooks/use-debounced-value";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { PageError, PageLoading } from "@/components/layout/PageStatus";

const KIND_LABELS: Record<string, string> = {
  acao: "Ação",
  etf: "ETF",
  fii: "FII",
  renda_fixa: "Renda fixa",
  internacional: "Internacional",
  cripto: "Cripto",
  outro: "Outro",
};

function kindLabel(kind: string) {
  return KIND_LABELS[kind] ?? kind;
}

type KindFilter = "todos" | "rv" | "fii";

function matchesKindFilter(asset: CatalogAsset, f: KindFilter): boolean {
  if (f === "todos") return true;
  if (f === "fii") return asset.kind === "fii";
  return asset.kind === "acao" || asset.kind === "etf";
}

export function BibliotecaAtivosPage() {
  const { getAccessToken } = useAuth();
  const token = getAccessToken();

  const assetsQ = useQuery({
    queryKey: ["catalog-assets"],
    queryFn: () => fetchAssets(getAccessToken()!),
    enabled: !!token,
  });

  const profilesQ = useQuery({
    queryKey: ["resistance-profiles"],
    queryFn: () => fetchResistanceProfiles(getAccessToken()!),
    enabled: !!token,
  });

  const profileByAssetId = useMemo(() => {
    const rows = profilesQ.data?.data ?? [];
    const m = new Map<string, ResistanceProfileRow>();
    for (const p of rows) m.set(p.asset_id, p);
    return m;
  }, [profilesQ.data?.data]);

  const [kindFilter, setKindFilter] = useState<KindFilter>("todos");
  const [tickerQuery, setTickerQuery] = useState("");
  const debouncedQ = useDebouncedValue(tickerQuery, 350);
  const [searchHits, setSearchHits] = useState<MarketSearchHit[]>([]);
  const [searchLoading, setSearchLoading] = useState(false);
  const [searchError, setSearchError] = useState<string | null>(null);

  const assets = assetsQ.data?.data ?? [];

  const filtered = useMemo(() => {
    const q = tickerQuery.trim().toUpperCase();
    return assets.filter((a) => {
      if (!matchesKindFilter(a, kindFilter)) return false;
      if (!q) return true;
      return a.ticker.toUpperCase().includes(q);
    });
  }, [assets, kindFilter, tickerQuery]);

  useEffect(() => {
    if (!token || debouncedQ.trim().length < 2) {
      setSearchHits([]);
      setSearchError(null);
      return;
    }
    let cancelled = false;
    setSearchLoading(true);
    setSearchError(null);
    void searchMarketTickers(debouncedQ, token)
      .then((hits) => {
        if (!cancelled) setSearchHits(hits.slice(0, 12));
      })
      .catch((e) => {
        if (!cancelled) {
          const msg =
            e instanceof ApiError
              ? e.message
              : "Não foi possível buscar tickers agora.";
          setSearchError(msg);
          setSearchHits([]);
        }
      })
      .finally(() => {
        if (!cancelled) setSearchLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [debouncedQ, token]);

  const errMsg =
    assetsQ.error instanceof ApiError
      ? assetsQ.error.message
      : profilesQ.error instanceof ApiError
        ? profilesQ.error.message
        : null;

  if (assetsQ.isLoading || profilesQ.isLoading) {
    return (
      <PageLoading title="Biblioteca de ativos" variant="simple" />
    );
  }

  if (assetsQ.isError || profilesQ.isError) {
    return (
      <PageError
        title="Biblioteca de ativos"
        message={errMsg ?? "Não foi possível carregar a biblioteca."}
      />
    );
  }

  return (
    <div className="flex flex-1 flex-col gap-8">
      <div>
        <h1 className="text-2xl font-semibold tracking-tight text-foreground">
          Biblioteca de ativos
        </h1>
        <p className="mt-1 text-sm text-muted-foreground">
          Catálogo de tickers com a sua{" "}
          <Link
            to="/app/nota-resistencia"
            className="font-medium text-primary underline-offset-4 hover:underline"
          >
            nota de resistência
          </Link>{" "}
          quando já calculada.
        </p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="text-base">Busca e filtros</CardTitle>
        </CardHeader>
        <CardContent className="flex flex-col gap-4">
          <div className="grid gap-4 sm:grid-cols-2">
            <div className="space-y-2">
              <Label htmlFor="bib-q">Filtrar por ticker</Label>
              <Input
                id="bib-q"
                value={tickerQuery}
                onChange={(e) => setTickerQuery(e.target.value)}
                placeholder="Ex.: PETR"
                autoComplete="off"
              />
              <p className="text-xs text-muted-foreground">
                Filtra a tabela abaixo. Sugestões da brapi (autocomplete):
              </p>
              {searchLoading && (
                <p className="text-xs text-muted-foreground">Buscando…</p>
              )}
              {searchError && (
                <p className="text-xs text-destructive">{searchError}</p>
              )}
              {searchHits.length > 0 && (
                <ul
                  className="max-h-40 overflow-auto rounded-md border border-border bg-muted/30 text-sm"
                  role="listbox"
                >
                  {searchHits.map((h) => (
                    <li key={h.ticker}>
                      <button
                        type="button"
                        className="flex w-full items-start gap-2 px-3 py-2 text-left hover:bg-muted"
                        onClick={() => setTickerQuery(h.ticker)}
                      >
                        <span className="font-mono font-medium">{h.ticker}</span>
                        <span className="text-muted-foreground">{h.name}</span>
                      </button>
                    </li>
                  ))}
                </ul>
              )}
            </div>
            <div className="space-y-2">
              <Label htmlFor="bib-kind">Tipo</Label>
              <select
                id="bib-kind"
                className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
                value={kindFilter}
                onChange={(e) => setKindFilter(e.target.value as KindFilter)}
              >
                <option value="todos">Todos</option>
                <option value="rv">Ações e ETFs</option>
                <option value="fii">FIIs</option>
              </select>
            </div>
          </div>
        </CardContent>
      </Card>

      <div className="overflow-x-auto rounded-xl border border-border/80 bg-card shadow-sm">
        <table className="w-full min-w-[32rem] border-collapse text-sm">
          <thead>
            <tr className="border-b border-border bg-muted/40 text-left">
              <th className="px-4 py-3 font-medium">Ticker</th>
              <th className="px-4 py-3 font-medium">Tipo</th>
              <th className="px-4 py-3 font-medium">Nota de resistência</th>
              <th className="px-4 py-3 font-medium">Elegível na calculadora</th>
            </tr>
          </thead>
          <tbody>
            {filtered.length === 0 ? (
              <tr>
                <td
                  colSpan={4}
                  className="px-4 py-8 text-center text-muted-foreground"
                >
                  Nenhum ativo corresponde aos filtros. Os tickers aparecem aqui
                  após serem usados na carteira ou no cadastro de ativos.
                </td>
              </tr>
            ) : (
              filtered.map((a) => {
                const prof = profileByAssetId.get(a.id);
                const score = prof?.computed_score;
                const eligible = prof?.eligible_for_allocation;
                return (
                  <tr
                    key={a.id}
                    className="border-b border-border/60 last:border-0"
                  >
                    <td className="px-4 py-3 font-mono font-medium">
                      {a.ticker}
                    </td>
                    <td className="px-4 py-3">{kindLabel(a.kind)}</td>
                    <td className="px-4 py-3 tabular-nums">
                      {score === null || score === undefined
                        ? "—"
                        : String(score)}
                    </td>
                    <td className="px-4 py-3">
                      {eligible === undefined
                        ? "—"
                        : eligible
                          ? "Sim"
                          : "Não"}
                    </td>
                  </tr>
                );
              })
            )}
          </tbody>
        </table>
      </div>

      <p className="text-xs text-muted-foreground">
        Dica: defina a nota em{" "}
        <Button variant="link" className="h-auto p-0 text-xs" asChild>
          <Link to="/app/nota-resistencia">Nota de resistência</Link>
        </Button>
        .
      </p>
    </div>
  );
}
