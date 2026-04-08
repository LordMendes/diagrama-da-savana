import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useCallback, useEffect, useMemo, useState } from "react";
import { useAuth } from "@/auth/auth-context";
import {
  createAporte,
  createHolding,
  createTargetAllocation,
  deleteHolding,
  fetchAportes,
  fetchHoldings,
  fetchPortfolios,
  fetchTargetAllocations,
  searchMarketTickers,
  updateTargetAllocation,
  type MarketSearchHit,
} from "@/api/carteira";
import { ApiError } from "@/lib/api";
import { formatBrl } from "@/lib/format-brl";
import { cn } from "@/lib/utils";
import { useDebouncedValue } from "@/hooks/use-debounced-value";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { PageError, PageLoading } from "@/components/layout/PageStatus";

const MACRO_ORDER = [
  "renda_fixa",
  "renda_variavel",
  "fiis",
  "internacional",
  "cripto",
  "outros",
] as const;

const MACRO_LABELS: Record<string, string> = {
  renda_fixa: "Renda fixa",
  renda_variavel: "Renda variável",
  fiis: "FIIs",
  internacional: "Internacional",
  cripto: "Cripto",
  outros: "Outros",
};

type MacroKey = (typeof MACRO_ORDER)[number];

function emptyTargetPercents(): Record<MacroKey, number> {
  return Object.fromEntries(MACRO_ORDER.map((m) => [m, 0])) as Record<
    MacroKey,
    number
  >;
}

const KIND_OPTIONS: { value: string; label: string }[] = [
  { value: "acao", label: "Ação" },
  { value: "etf", label: "ETF" },
  { value: "fii", label: "FII" },
  { value: "renda_fixa", label: "Renda fixa" },
  { value: "internacional", label: "Internacional" },
  { value: "cripto", label: "Cripto" },
  { value: "outro", label: "Outro" },
];

function kindLabel(kind: string) {
  return KIND_OPTIONS.find((k) => k.value === kind)?.label ?? kind;
}

export function CarteiraPage() {
  const { getAccessToken } = useAuth();
  const token = getAccessToken();
  const queryClient = useQueryClient();

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

  const targetsQ = useQuery({
    queryKey: ["targets", portfolioId],
    queryFn: () => fetchTargetAllocations(portfolioId!, getAccessToken()!),
    enabled: !!portfolioId && !!token,
  });

  const holdingsQ = useQuery({
    queryKey: ["holdings", portfolioId],
    queryFn: () => fetchHoldings(portfolioId!, getAccessToken()!),
    enabled: !!portfolioId && !!token,
  });

  const aportesQ = useQuery({
    queryKey: ["aportes", portfolioId],
    queryFn: () => fetchAportes(portfolioId!, getAccessToken()!),
    enabled: !!portfolioId && !!token,
  });

  const [targetDraft, setTargetDraft] =
    useState<Record<MacroKey, number>>(emptyTargetPercents);
  useEffect(() => {
    const rows = targetsQ.data?.data ?? [];
    const next = emptyTargetPercents();
    for (const m of MACRO_ORDER) {
      const row = rows.find((r) => r.macro_class === m);
      next[m] = row
        ? Math.min(
            100,
            Math.max(0, Math.round(parseFloat(row.target_percent))),
          )
        : 0;
    }
    setTargetDraft(next);
  }, [targetsQ.data]);

  const targetTotalPercent = useMemo(
    () => MACRO_ORDER.reduce((sum, m) => sum + (targetDraft[m] ?? 0), 0),
    [targetDraft],
  );

  const targetsExceed100 = targetTotalPercent > 100;

  const saveTargetsM = useMutation({
    mutationFn: async () => {
      const t = getAccessToken();
      if (!portfolioId || !t) throw new Error("Sessão inválida");
      const sum = MACRO_ORDER.reduce((s, m) => s + (targetDraft[m] ?? 0), 0);
      if (sum > 100) throw new Error("A soma das metas não pode ultrapassar 100%.");
      const existing = targetsQ.data?.data ?? [];
      const byMacro = new Map(existing.map((r) => [r.macro_class, r]));
      for (const macro of MACRO_ORDER) {
        const n = targetDraft[macro] ?? 0;
        const row = byMacro.get(macro);
        if (n === 0 && !row) continue;
        const raw = String(n);
        if (row) {
          await updateTargetAllocation(
            portfolioId,
            row.id,
            { target_percent: raw },
            t,
          );
        } else {
          await createTargetAllocation(
            portfolioId,
            { macro_class: macro, target_percent: raw },
            t,
          );
        }
      }
    },
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: ["targets", portfolioId] });
      void queryClient.invalidateQueries({ queryKey: ["portfolio-summary"] });
    },
  });

  const [tickerQuery, setTickerQuery] = useState("");
  const debouncedQ = useDebouncedValue(tickerQuery, 350);
  const [searchHits, setSearchHits] = useState<MarketSearchHit[]>([]);
  const [searchLoading, setSearchLoading] = useState(false);
  const [selectedTicker, setSelectedTicker] = useState<MarketSearchHit | null>(
    null,
  );
  const [newKind, setNewKind] = useState("acao");
  const [newQty, setNewQty] = useState("");
  const [newAvg, setNewAvg] = useState("");

  useEffect(() => {
    if (!token || debouncedQ.trim().length < 2) {
      setSearchHits([]);
      return;
    }
    let cancelled = false;
    setSearchLoading(true);
    void searchMarketTickers(debouncedQ, token)
      .then((hits) => {
        if (!cancelled) setSearchHits(hits.slice(0, 12));
      })
      .catch(() => {
        if (!cancelled) setSearchHits([]);
      })
      .finally(() => {
        if (!cancelled) setSearchLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [debouncedQ, token]);

  const addHoldingM = useMutation({
    mutationFn: async () => {
      const t = getAccessToken();
      if (!portfolioId || !t) throw new Error("Sessão inválida");
      if (!selectedTicker) throw new Error("Escolha um ticker na busca.");
      const qty = newQty.trim().replace(",", ".");
      const avg = newAvg.trim().replace(",", ".");
      await createHolding(
        portfolioId,
        {
          ticker: selectedTicker.ticker,
          kind: newKind,
          quantity: qty,
          average_price: avg,
        },
        t,
      );
    },
    onSuccess: () => {
      setTickerQuery("");
      setSelectedTicker(null);
      setNewQty("");
      setNewAvg("");
      void queryClient.invalidateQueries({ queryKey: ["holdings", portfolioId] });
      void queryClient.invalidateQueries({ queryKey: ["portfolio-summary"] });
    },
  });

  const removeHoldingM = useMutation({
    mutationFn: async (holdingId: string) => {
      const t = getAccessToken();
      if (!portfolioId || !t) throw new Error("Sessão inválida");
      await deleteHolding(portfolioId, holdingId, t);
    },
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: ["holdings", portfolioId] });
      void queryClient.invalidateQueries({ queryKey: ["portfolio-summary"] });
    },
  });

  const [aporteAmount, setAporteAmount] = useState("");
  const [aporteNote, setAporteNote] = useState("");
  const [aporteDate, setAporteDate] = useState(() =>
    new Date().toISOString().slice(0, 10),
  );

  const addAporteM = useMutation({
    mutationFn: async () => {
      const t = getAccessToken();
      if (!portfolioId || !t) throw new Error("Sessão inválida");
      const amount = aporteAmount.trim().replace(",", ".");
      await createAporte(
        portfolioId,
        {
          amount,
          note: aporteNote.trim() || undefined,
          occurred_on: aporteDate,
        },
        t,
      );
    },
    onSuccess: () => {
      setAporteAmount("");
      setAporteNote("");
      void queryClient.invalidateQueries({ queryKey: ["aportes", portfolioId] });
      void queryClient.invalidateQueries({ queryKey: ["portfolio-summary"] });
    },
  });

  const err =
    portfoliosQ.error instanceof ApiError
      ? portfoliosQ.error.message
      : null;

  const holdings = holdingsQ.data?.data ?? [];
  const aportes = aportesQ.data?.data ?? [];

  const onPickHit = useCallback((h: MarketSearchHit) => {
    setSelectedTicker(h);
    setTickerQuery(h.ticker);
    setSearchHits([]);
  }, []);

  const formError = useMemo(() => {
    if (addHoldingM.error instanceof ApiError) return addHoldingM.error.message;
    if (addHoldingM.error instanceof Error) return addHoldingM.error.message;
    return null;
  }, [addHoldingM.error]);

  const saveTargetsErr = useMemo(() => {
    if (!saveTargetsM.isError) return null;
    if (saveTargetsM.error instanceof ApiError)
      return saveTargetsM.error.message;
    return "Não foi possível salvar as metas. Tente novamente.";
  }, [saveTargetsM.isError, saveTargetsM.error]);

  const addAporteErr = useMemo(() => {
    if (!addAporteM.isError) return null;
    if (addAporteM.error instanceof ApiError) return addAporteM.error.message;
    return "Não foi possível registrar o aporte. Tente novamente.";
  }, [addAporteM.isError, addAporteM.error]);

  if (portfoliosQ.isLoading) {
    return <PageLoading title="Carteira" variant="simple" />;
  }

  if (err) {
    return <PageError title="Carteira" message={err} />;
  }

  if (!portfolioId) {
    return (
      <p className="text-sm text-muted-foreground">
        Nenhuma carteira disponível. Tente sair e entrar novamente.
      </p>
    );
  }

  return (
    <div className="flex flex-col gap-10">
      <div>
        <h1 className="text-2xl font-semibold tracking-tight">Carteira</h1>
        <p className="mt-1 text-sm text-muted-foreground">
          Metas por classe macro, posições com quantidade e preço médio, e
          registro de aportes.
        </p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="text-lg">Metas de alocação (%)</CardTitle>
          <p className="text-sm text-muted-foreground">
            Ajuste o percentual alvo por classe (0 a 100%). A soma de todas as
            metas não pode ser maior que 100%.
          </p>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid gap-6 sm:grid-cols-2">
            {MACRO_ORDER.map((macro) => (
              <div key={macro} className="space-y-2">
                <div className="flex items-center justify-between gap-2">
                  <Label htmlFor={`meta-${macro}`}>{MACRO_LABELS[macro]}</Label>
                  <span className="text-sm tabular-nums text-muted-foreground">
                    {targetDraft[macro] ?? 0}%
                  </span>
                </div>
                <input
                  id={`meta-${macro}`}
                  type="range"
                  min={0}
                  max={100}
                  step={1}
                  value={targetDraft[macro] ?? 0}
                  onChange={(e) =>
                    setTargetDraft((d) => ({
                      ...d,
                      [macro]: Number(e.target.value),
                    }))
                  }
                  disabled={targetsQ.isLoading}
                  className={cn(
                    "h-2 w-full cursor-pointer appearance-none rounded-full bg-muted accent-primary",
                    "disabled:cursor-not-allowed disabled:opacity-50",
                  )}
                />
              </div>
            ))}
          </div>
          <div className="flex items-center justify-between border-t border-border pt-3 text-sm">
            <span className="font-medium">Total</span>
            <span
              className={cn(
                "tabular-nums font-medium",
                targetsExceed100 && "text-destructive",
              )}
            >
              {targetTotalPercent}%
            </span>
          </div>
          {targetsExceed100 ? (
            <p
              className="rounded-md border border-destructive/50 bg-destructive/10 px-3 py-2 text-sm text-destructive"
              role="alert"
            >
              A soma das metas não pode ultrapassar 100%. Reduza os percentuais
              antes de salvar.
            </p>
          ) : null}
          <Button
            type="button"
            disabled={saveTargetsM.isPending || targetsExceed100}
            onClick={() => saveTargetsM.mutate()}
          >
            {saveTargetsM.isPending ? "Salvando…" : "Salvar metas"}
          </Button>
          {saveTargetsErr ? (
            <p className="text-sm text-destructive" role="alert">
              {saveTargetsErr}
            </p>
          ) : null}
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle className="text-lg">Posições</CardTitle>
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="space-y-3 rounded-lg border border-border/60 bg-muted/20 p-4">
            <p className="text-sm font-medium">Adicionar ativo</p>
            <div className="relative space-y-1.5">
              <Label htmlFor="ticker-search">Buscar ticker (brapi)</Label>
              <Input
                id="ticker-search"
                autoComplete="off"
                placeholder="Digite parte do ticker…"
                value={tickerQuery}
                onChange={(e) => {
                  setTickerQuery(e.target.value);
                  setSelectedTicker(null);
                }}
              />
              {searchLoading ? (
                <p className="text-xs text-muted-foreground">Buscando…</p>
              ) : null}
              {searchHits.length > 0 ? (
                <ul
                  className="absolute z-20 mt-1 max-h-48 w-full overflow-auto rounded-md border border-border bg-card py-1 shadow-md"
                  role="listbox"
                >
                  {searchHits.map((h) => (
                    <li key={h.ticker}>
                      <button
                        type="button"
                        className="flex w-full flex-col items-start px-3 py-2 text-left text-sm hover:bg-muted"
                        onClick={() => onPickHit(h)}
                      >
                        <span className="font-medium">{h.ticker}</span>
                        <span className="text-xs text-muted-foreground">
                          {h.name}
                        </span>
                      </button>
                    </li>
                  ))}
                </ul>
              ) : null}
            </div>
            <div className="grid gap-4 sm:grid-cols-3">
              <div className="space-y-1.5">
                <Label htmlFor="kind">Tipo</Label>
                <select
                  id="kind"
                  className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
                  value={newKind}
                  onChange={(e) => setNewKind(e.target.value)}
                >
                  {KIND_OPTIONS.map((o) => (
                    <option key={o.value} value={o.value}>
                      {o.label}
                    </option>
                  ))}
                </select>
              </div>
              <div className="space-y-1.5">
                <Label htmlFor="qty">Quantidade</Label>
                <Input
                  id="qty"
                  inputMode="decimal"
                  placeholder="0"
                  value={newQty}
                  onChange={(e) => setNewQty(e.target.value)}
                />
              </div>
              <div className="space-y-1.5">
                <Label htmlFor="avg">Preço médio (R$)</Label>
                <Input
                  id="avg"
                  inputMode="decimal"
                  placeholder="0,00"
                  value={newAvg}
                  onChange={(e) => setNewAvg(e.target.value)}
                />
              </div>
            </div>
            {selectedTicker ? (
              <p className="text-xs text-muted-foreground">
                Selecionado: {selectedTicker.ticker} — {selectedTicker.name}
              </p>
            ) : null}
            {formError ? (
              <p className="text-sm text-destructive">{formError}</p>
            ) : null}
            <Button
              type="button"
              disabled={addHoldingM.isPending}
              onClick={() => addHoldingM.mutate()}
            >
              {addHoldingM.isPending ? "Adicionando…" : "Adicionar à carteira"}
            </Button>
          </div>

          <div className="overflow-x-auto">
            {holdingsQ.isLoading ? (
              <p className="text-sm text-muted-foreground">Carregando posições…</p>
            ) : holdings.length === 0 ? (
              <p className="text-sm text-muted-foreground">
                Nenhuma posição ainda.
              </p>
            ) : (
              <table className="w-full min-w-[36rem] text-left text-sm">
                <thead>
                  <tr className="border-b border-border/60 text-muted-foreground">
                    <th className="py-2 pr-4 font-medium">Ticker</th>
                    <th className="py-2 pr-4 font-medium">Tipo</th>
                    <th className="py-2 pr-4 font-medium">Qtd</th>
                    <th className="py-2 pr-4 font-medium">Preço médio</th>
                    <th className="py-2 font-medium" />
                  </tr>
                </thead>
                <tbody>
                  {holdings.map((h) => (
                    <tr key={h.id} className="border-b border-border/40">
                      <td className="py-2 pr-4 font-medium">
                        {h.asset?.ticker ?? "—"}
                      </td>
                      <td className="py-2 pr-4">
                        {h.asset ? kindLabel(h.asset.kind) : "—"}
                      </td>
                      <td className="py-2 pr-4 tabular-nums">
                        {h.quantity.replace(".", ",")}
                      </td>
                      <td className="py-2 pr-4 tabular-nums">
                        {formatBrl(h.average_price)}
                      </td>
                      <td className="py-2">
                        <Button
                          type="button"
                          variant="outline"
                          size="sm"
                          disabled={removeHoldingM.isPending}
                          onClick={() => {
                            if (
                              window.confirm(
                                "Remover esta posição da carteira?",
                              )
                            ) {
                              removeHoldingM.mutate(h.id);
                            }
                          }}
                        >
                          Remover
                        </Button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle className="text-lg">Aportes recentes</CardTitle>
          <p className="text-sm text-muted-foreground">
            Registre valores depositados na carteira para acompanhar no painel.
          </p>
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="grid gap-4 sm:grid-cols-3">
            <div className="space-y-1.5">
              <Label htmlFor="ap-amt">Valor (R$)</Label>
              <Input
                id="ap-amt"
                inputMode="decimal"
                value={aporteAmount}
                onChange={(e) => setAporteAmount(e.target.value)}
              />
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="ap-dt">Data</Label>
              <Input
                id="ap-dt"
                type="date"
                value={aporteDate}
                onChange={(e) => setAporteDate(e.target.value)}
              />
            </div>
            <div className="space-y-1.5 sm:col-span-1">
              <Label htmlFor="ap-note">Observação (opcional)</Label>
              <Input
                id="ap-note"
                value={aporteNote}
                onChange={(e) => setAporteNote(e.target.value)}
              />
            </div>
          </div>
          <Button
            type="button"
            disabled={addAporteM.isPending}
            onClick={() => addAporteM.mutate()}
          >
            {addAporteM.isPending ? "Registrando…" : "Registrar aporte"}
          </Button>
          {addAporteErr ? (
            <p className="text-sm text-destructive" role="alert">
              {addAporteErr}
            </p>
          ) : null}

          <div className="overflow-x-auto">
            {aportesQ.isLoading ? (
              <p className="text-sm text-muted-foreground">Carregando…</p>
            ) : aportes.length === 0 ? (
              <p className="text-sm text-muted-foreground">
                Nenhum aporte registrado.
              </p>
            ) : (
              <table className="w-full min-w-[28rem] text-left text-sm">
                <thead>
                  <tr className="border-b border-border/60 text-muted-foreground">
                    <th className="py-2 pr-4 font-medium">Data</th>
                    <th className="py-2 pr-4 font-medium">Valor</th>
                    <th className="py-2 font-medium">Observação</th>
                  </tr>
                </thead>
                <tbody>
                  {aportes.map((a) => (
                    <tr key={a.id} className="border-b border-border/40">
                      <td className="py-2 pr-4 tabular-nums text-muted-foreground">
                        {formatDatePt(a.occurred_on)}
                      </td>
                      <td className="py-2 pr-4 tabular-nums">
                        {formatBrl(a.amount)}
                      </td>
                      <td className="py-2 text-muted-foreground">
                        {a.note ?? "—"}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

function formatDatePt(iso: string) {
  const [y, m, d] = iso.split("-").map(Number);
  if (!y || !m || !d) return iso;
  return `${String(d).padStart(2, "0")}/${String(m).padStart(2, "0")}/${y}`;
}
