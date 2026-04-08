import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useEffect, useMemo, useState } from "react";
import { useAuth } from "@/auth/auth-context";
import {
  fetchHoldings,
  fetchPortfolios,
  type Holding,
} from "@/api/carteira";
import {
  fetchResistanceCriteria,
  fetchResistanceProfile,
  upsertResistanceProfile,
  type ResistanceCriterion,
} from "@/api/resistencia";
import { ApiError } from "@/lib/api";
import { previewScore } from "@/lib/resistance-score";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Label } from "@/components/ui/label";
import { PageError, PageLoading } from "@/components/layout/PageStatus";

const RESISTANCE_KINDS = new Set(["acao", "etf", "fii"]);

/** Stable fallbacks so hooks that depend on array identity do not re-run every render. */
const EMPTY_HOLDINGS: Holding[] = [];
const EMPTY_CRITERIA: ResistanceCriterion[] = [];

function criteriaKindForAsset(kind: string): "acao" | "fii" | null {
  if (kind === "fii") return "fii";
  if (kind === "acao" || kind === "etf") return "acao";
  return null;
}

function emptyCriteria(defs: ResistanceCriterion[]): Record<string, number> {
  const o: Record<string, number> = {};
  for (const d of defs) o[d.id] = 0;
  return o;
}

export function NotaResistenciaPage() {
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

  const holdingsQ = useQuery({
    queryKey: ["holdings", portfolioId],
    queryFn: () => fetchHoldings(portfolioId!, getAccessToken()!),
    enabled: !!portfolioId && !!token,
  });

  const holdings = holdingsQ.data?.data ?? EMPTY_HOLDINGS;
  const eligibleHoldings = useMemo(
    () =>
      holdings.filter(
        (h): h is Holding & { asset: NonNullable<Holding["asset"]> } =>
          !!h.asset && RESISTANCE_KINDS.has(h.asset.kind),
      ),
    [holdings],
  );

  const [assetId, setAssetId] = useState<string | null>(null);

  useEffect(() => {
    if (!assetId && eligibleHoldings.length > 0) {
      setAssetId(eligibleHoldings[0].asset!.id);
    }
  }, [assetId, eligibleHoldings]);

  const selected = eligibleHoldings.find((h) => h.asset?.id === assetId);
  const assetKind = selected?.asset?.kind ?? null;
  const criteriaKind = assetKind ? criteriaKindForAsset(assetKind) : null;

  const defsQ = useQuery({
    queryKey: ["resistance-criteria", criteriaKind],
    queryFn: () =>
      fetchResistanceCriteria(criteriaKind!, getAccessToken()!),
    enabled: !!token && !!criteriaKind,
  });

  const profileQ = useQuery({
    queryKey: ["resistance-profile", assetId],
    queryFn: async () => {
      try {
        return await fetchResistanceProfile(assetId!, getAccessToken()!);
      } catch (e) {
        if (e instanceof ApiError && e.status === 404) return null;
        throw e;
      }
    },
    enabled: !!token && !!assetId,
  });

  const definitions = defsQ.data?.data ?? EMPTY_CRITERIA;

  const [draft, setDraft] = useState<Record<string, number>>({});

  useEffect(() => {
    if (definitions.length === 0) {
      setDraft({});
      return;
    }
    const base = emptyCriteria(definitions);
    const loaded = profileQ.data?.data?.criteria;
    if (loaded && typeof loaded === "object") {
      for (const id of Object.keys(base)) {
        const v = loaded[id];
        if (v === -1 || v === 0 || v === 1) base[id] = v;
      }
    }
    setDraft(base);
  }, [definitions, profileQ.data, assetId]);

  const preview = useMemo(() => previewScore(draft), [draft]);

  const saveM = useMutation({
    mutationFn: async () => {
      const t = getAccessToken();
      if (!assetId || !t) throw new Error("Sessão inválida");
      return upsertResistanceProfile(assetId, draft, t);
    },
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: ["resistance-profile", assetId] });
      void queryClient.invalidateQueries({ queryKey: ["resistance-profiles"] });
    },
  });

  const loadErr =
    profileQ.error instanceof ApiError
      ? profileQ.error.message
      : profileQ.error instanceof Error
        ? profileQ.error.message
        : null;

  const portfoliosErr =
    portfoliosQ.error instanceof ApiError
      ? portfoliosQ.error.message
      : portfoliosQ.error instanceof Error
        ? portfoliosQ.error.message
        : null;

  const holdingsErr =
    holdingsQ.error instanceof ApiError
      ? holdingsQ.error.message
      : holdingsQ.error instanceof Error
        ? holdingsQ.error.message
        : null;

  if (portfoliosQ.isLoading) {
    return <PageLoading title="Nota de resistência" variant="simple" />;
  }

  if (portfoliosQ.isError) {
    return (
      <PageError
        title="Nota de resistência"
        message={
          portfoliosErr ?? "Não foi possível carregar a carteira. Tente novamente."
        }
      />
    );
  }

  if (!portfolioId) {
    return (
      <div className="flex flex-col gap-2">
        <h1 className="text-2xl font-semibold tracking-tight">
          Nota de resistência
        </h1>
        <p className="text-sm text-muted-foreground" role="status">
          Nenhuma carteira disponível.
        </p>
      </div>
    );
  }

  if (holdingsQ.isLoading) {
    return (
      <PageLoading
        title="Nota de resistência"
        variant="simple"
        description="Carregando posições…"
      />
    );
  }

  if (holdingsQ.isError) {
    return (
      <PageError
        title="Nota de resistência"
        message={
          holdingsErr ??
          "Não foi possível carregar as posições. Tente novamente."
        }
      />
    );
  }

  return (
    <div className="flex flex-col gap-8">
      <div>
        <h1 className="text-2xl font-semibold tracking-tight">
          Nota de resistência
        </h1>
        <p className="mt-1 text-sm text-muted-foreground">
          Checklist por critério (−1, 0 ou +1). A nota final fica entre −5 e +10.
          Ativos com nota zero ou negativa não entram na alocação por peso
          (calculadora de aporte).
        </p>
      </div>

      {eligibleHoldings.length === 0 ? (
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">Nenhum ativo elegível</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-sm text-muted-foreground">
              Adicione à carteira pelo menos uma ação, ETF ou FII para preencher
              a nota de resistência.
            </p>
          </CardContent>
        </Card>
      ) : (
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">Critérios por ativo</CardTitle>
            <p className="text-sm text-muted-foreground">
              Escolha uma posição da carteira. ETFs usam o mesmo checklist de
              ações.
            </p>
          </CardHeader>
          <CardContent className="space-y-6">
            <div className="space-y-2">
              <Label htmlFor="holding-pick">Posição</Label>
              <select
                id="holding-pick"
                className="flex h-10 w-full max-w-md rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
                value={assetId ?? ""}
                onChange={(e) => setAssetId(e.target.value || null)}
              >
                {eligibleHoldings.map((h) => (
                  <option key={h.id} value={h.asset!.id}>
                    {h.asset!.ticker} ({h.asset!.kind})
                  </option>
                ))}
              </select>
            </div>

            {profileQ.isLoading || defsQ.isLoading ? (
              <p className="text-sm text-muted-foreground">
                Carregando critérios…
              </p>
            ) : loadErr ? (
              <p className="text-sm text-destructive" role="alert">
                {loadErr}
              </p>
            ) : definitions.length === 0 ? (
              <p className="text-sm text-muted-foreground">
                Não foi possível carregar os critérios.
              </p>
            ) : (
              <>
                <div
                  className="rounded-lg border border-border/60 bg-muted/15 p-4"
                  role="status"
                >
                  <p className="text-sm font-medium text-foreground">
                    Nota final (prévia):{" "}
                    <span className="tabular-nums text-lg">{preview}</span>
                  </p>
                  <p className="mt-1 text-xs text-muted-foreground">
                    {preview <= 0
                      ? "Este ativo ficará fora da alocação por peso até a nota ficar positiva."
                      : "Elegível para a alocação por peso na calculadora de aporte."}
                  </p>
                </div>

                <ul className="space-y-4">
                  {definitions.map((c) => (
                    <li
                      key={c.id}
                      className="flex flex-col gap-2 border-b border-border/40 pb-4 last:border-0 sm:flex-row sm:items-center sm:justify-between"
                    >
                      <p className="max-w-xl text-sm leading-snug">{c.label}</p>
                      <div className="flex shrink-0 gap-1">
                        {([-1, 0, 1] as const).map((v) => (
                          <Button
                            key={v}
                            type="button"
                            size="sm"
                            variant={draft[c.id] === v ? "default" : "outline"}
                            className="min-w-[2.75rem]"
                            onClick={() =>
                              setDraft((d) => ({ ...d, [c.id]: v }))
                            }
                          >
                            {v > 0 ? `+${v}` : String(v)}
                          </Button>
                        ))}
                      </div>
                    </li>
                  ))}
                </ul>

                <div className="flex flex-wrap items-center gap-3">
                  <Button
                    type="button"
                    disabled={saveM.isPending}
                    onClick={() => saveM.mutate()}
                  >
                    {saveM.isPending ? "Salvando…" : "Salvar nota"}
                  </Button>
                  {saveM.isError ? (
                    <span className="text-sm text-destructive">
                      Não foi possível salvar. Verifique os valores e tente de
                      novo.
                    </span>
                  ) : null}
                  {saveM.isSuccess ? (
                    <span className="text-sm text-muted-foreground">
                      Nota salva (servidor:{" "}
                      {saveM.data?.data.computed_score ?? "—"}).
                    </span>
                  ) : null}
                </div>
              </>
            )}
          </CardContent>
        </Card>
      )}
    </div>
  );
}
