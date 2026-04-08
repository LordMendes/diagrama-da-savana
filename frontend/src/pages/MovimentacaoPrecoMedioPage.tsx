import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useCallback, useMemo, useState } from "react";
import { useAuth } from "@/auth/auth-context";
import { createHolding, fetchHoldings, fetchPortfolios } from "@/api/carteira";
import { computePrecoMedioPorAtivo } from "@/lib/movimentacao-preco-medio";
import {
  MovimentacaoPlanilhaError,
  parseMovimentacaoXlsx,
} from "@/lib/movimentacao-xlsx";
import type { AtivoPrecoMedioResult } from "@/lib/movimentacao-types";
import { ApiError } from "@/lib/api";
import { formatBrl } from "@/lib/format-brl";
import { inferAssetKindFromTicker } from "@/lib/infer-asset-kind";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";

function formatQty(n: number): string {
  return n.toLocaleString("pt-BR", {
    minimumFractionDigits: 0,
    maximumFractionDigits: 8,
  });
}

/** Valor decimal para a API (ponto como separador, sem agrupamento). */
function formatDecimalApi(n: number, maxFrac = 8): string {
  if (!Number.isFinite(n)) return "0";
  const s = n.toFixed(maxFrac).replace(/\.?0+$/, "");
  return s === "" ? "0" : s;
}

function RowAddToWalletButton(props: {
  row: AtivoPrecoMedioResult;
  portfolioId: string | null;
  alreadyInWallet: boolean;
  isPending: boolean;
  onAdd: () => void;
}) {
  const { row, portfolioId, alreadyInWallet, isPending, onAdd } = props;
  const canAdd =
    !!portfolioId &&
    row.quantidade > 0 &&
    row.precoMedio !== null &&
    !alreadyInWallet;

  if (alreadyInWallet) {
    return (
      <span className="text-xs text-muted-foreground">Na carteira</span>
    );
  }

  return (
    <Button
      type="button"
      size="sm"
      variant="secondary"
      disabled={!canAdd || isPending}
      title={
        !portfolioId
          ? "Carteira indisponível"
          : row.quantidade <= 0
            ? "Quantidade zero"
            : row.precoMedio === null
              ? "Preço médio indefinido"
              : "Adiciona só este ativo à carteira principal"
      }
      onClick={() => onAdd()}
    >
      {isPending ? "Adicionando…" : "Adicionar"}
    </Button>
  );
}

export function MovimentacaoPrecoMedioPage() {
  const { getAccessToken } = useAuth();
  const token = getAccessToken();
  const queryClient = useQueryClient();

  const [erro, setErro] = useState<string | null>(null);
  const [nomeArquivo, setNomeArquivo] = useState<string | null>(null);
  const [report, setReport] = useState<ReturnType<
    typeof computePrecoMedioPorAtivo
  > | null>(null);
  const [carteiraErro, setCarteiraErro] = useState<string | null>(null);

  const portfoliosQ = useQuery({
    queryKey: ["portfolios"],
    queryFn: async () => {
      const t = getAccessToken();
      if (!t) throw new Error("Não autenticado");
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

  const tickersNaCarteira = useMemo(() => {
    const set = new Set<string>();
    for (const h of holdingsQ.data?.data ?? []) {
      const t = h.asset?.ticker;
      if (t) set.add(t.toUpperCase());
    }
    return set;
  }, [holdingsQ.data]);

  const addHoldingM = useMutation({
    mutationFn: async (row: AtivoPrecoMedioResult) => {
      const t = getAccessToken();
      if (!portfolioId || !t) throw new Error("Sessão inválida");
      if (row.quantidade <= 0) throw new Error("Quantidade inválida");
      return createHolding(
        portfolioId,
        {
          ticker: row.ticker,
          kind: inferAssetKindFromTicker(row.ticker),
          quantity: formatDecimalApi(row.quantidade),
          average_price: formatDecimalApi(
            row.precoMedio !== null ? row.precoMedio : 0,
          ),
        },
        t,
      );
    },
    onSuccess: () => {
      setCarteiraErro(null);
      void queryClient.invalidateQueries({ queryKey: ["holdings", portfolioId] });
      void queryClient.invalidateQueries({ queryKey: ["portfolio-summary"] });
    },
    onError: (e: unknown) => {
      if (e instanceof ApiError) {
        const fieldMsgs = e.fields
          ? Object.values(e.fields).flat()
          : [];
        const joined = [...fieldMsgs, e.message].filter(Boolean).join(" ");
        const low = joined.toLowerCase();
        if (low.includes("já") && low.includes("carteira")) {
          setCarteiraErro(
            "Este ativo já está na carteira. Ajuste quantidade e preço em Carteira.",
          );
        } else {
          const first =
            fieldMsgs[0] ??
            (e.message !== "Verifique os campos destacados." ? e.message : null);
          setCarteiraErro(first ?? "Não foi possível adicionar à carteira.");
        }
      } else {
        setCarteiraErro("Não foi possível adicionar à carteira.");
      }
    },
  });

  const onFile = useCallback(async (file: File | null) => {
    setErro(null);
    setCarteiraErro(null);
    setReport(null);
    setNomeArquivo(null);
    if (!file) return;
    if (!/\.xlsx$/i.test(file.name)) {
      setErro("Envie um arquivo .xlsx exportado da corretora.");
      return;
    }
    setNomeArquivo(file.name);
    try {
      const ab = await file.arrayBuffer();
      const rows = parseMovimentacaoXlsx(ab);
      setReport(computePrecoMedioPorAtivo(rows));
    } catch (e) {
      if (e instanceof MovimentacaoPlanilhaError) {
        setErro(e.message);
      } else {
        setErro(
          "Não foi possível ler o arquivo. Confira se é o export de movimentação (.xlsx).",
        );
      }
    }
  }, []);

  return (
    <div className="flex flex-col gap-8">
      <header className="space-y-2">
        <h1 className="text-2xl font-semibold tracking-tight">
          Preço médio por movimentação
        </h1>
        <p className="max-w-2xl text-sm text-muted-foreground">
          Envie a planilha de movimentação (mesmo layout do export BTG: colunas
          Entrada/Saída, Data, Movimentação, Produto, Quantidade, Preço unitário e
          Valor da Operação). O cálculo usa preço médio de custo sobre compras e
          vendas; proventos, empréstimo e renda fixa são ignorados. Transferências
          sem preço assumem o preço médio atual.
        </p>
      </header>

      <Card>
        <CardHeader>
          <CardTitle>Arquivo</CardTitle>
          <CardDescription>
            Selecione o .xlsx exportado da sua corretora. Nada é enviado ao
            servidor — o processamento é feito no navegador.
          </CardDescription>
        </CardHeader>
        <CardContent className="flex flex-wrap items-center gap-3">
          <input
            type="file"
            accept=".xlsx,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
            className="text-sm file:mr-3 file:rounded-md file:border-0 file:bg-primary file:px-3 file:py-1.5 file:text-sm file:font-medium file:text-primary-foreground hover:file:bg-primary/90"
            onChange={(e) => void onFile(e.target.files?.[0] ?? null)}
          />
          {nomeArquivo ? (
            <span className="text-sm text-muted-foreground">{nomeArquivo}</span>
          ) : null}
          {report ? (
            <Button
              type="button"
              variant="outline"
              size="sm"
              onClick={() => {
                setReport(null);
                setNomeArquivo(null);
                setErro(null);
                setCarteiraErro(null);
              }}
            >
              Limpar
            </Button>
          ) : null}
        </CardContent>
      </Card>

      {erro ? (
        <p className="rounded-lg border border-destructive/40 bg-destructive/10 px-4 py-3 text-sm text-destructive">
          {erro}
        </p>
      ) : null}

      {carteiraErro ? (
        <p className="rounded-lg border border-destructive/40 bg-destructive/10 px-4 py-3 text-sm text-destructive">
          {carteiraErro}
        </p>
      ) : null}

      {!portfolioId && token && !portfoliosQ.isLoading ? (
        <p className="text-sm text-muted-foreground">
          Nenhuma carteira encontrada. Crie uma carteira em Carteira antes de
          importar posições.
        </p>
      ) : null}

      {report && report.avisos.length > 0 ? (
        <div className="rounded-lg border border-border/80 bg-muted/30 px-4 py-3 text-sm text-muted-foreground">
          <p className="font-medium text-foreground">Avisos</p>
          <ul className="mt-2 list-inside list-disc space-y-1">
            {report.avisos.map((a, i) => (
              <li key={i}>{a}</li>
            ))}
          </ul>
        </div>
      ) : null}

      {report && report.ativos.length > 0 ? (
        <Card>
          <CardHeader>
            <CardTitle>Resultado por ativo</CardTitle>
            <CardDescription>
              Quantidade líquida e preço médio de custo após processar as linhas
              em ordem cronológica. Use &quot;Adicionar à carteira&quot; só nas
              linhas que quiser enviar para a carteira principal.
            </CardDescription>
          </CardHeader>
          <CardContent className="overflow-x-auto">
            <table className="w-full min-w-[44rem] border-collapse text-sm">
              <thead>
                <tr className="border-b border-border text-left">
                  <th className="pb-2 pr-4 font-medium">Ticker</th>
                  <th className="pb-2 pr-4 font-medium">Produto</th>
                  <th className="pb-2 pr-4 font-medium text-right">Quantidade</th>
                  <th className="pb-2 pr-4 font-medium text-right">
                    Preço médio
                  </th>
                  <th className="pb-2 pr-4 font-medium text-right">Custo total</th>
                  <th className="pb-2 font-medium text-right">Carteira</th>
                </tr>
              </thead>
              <tbody>
                {report.ativos.map((a) => (
                  <tr
                    key={a.ticker}
                    className="border-b border-border/60 last:border-0"
                  >
                    <td className="py-2 pr-4 font-mono text-xs">{a.ticker}</td>
                    <td className="max-w-[14rem] truncate py-2 pr-4 text-muted-foreground">
                      {a.produtoLabel}
                    </td>
                    <td className="py-2 pr-4 text-right tabular-nums">
                      {formatQty(a.quantidade)}
                    </td>
                    <td className="py-2 pr-4 text-right tabular-nums">
                      {a.precoMedio !== null ? formatBrl(a.precoMedio) : "—"}
                    </td>
                    <td className="py-2 pr-4 text-right tabular-nums">
                      {formatBrl(a.custoTotal)}
                    </td>
                    <td className="py-2 text-right">
                      <RowAddToWalletButton
                        row={a}
                        portfolioId={portfolioId}
                        alreadyInWallet={tickersNaCarteira.has(
                          a.ticker.toUpperCase(),
                        )}
                        isPending={
                          addHoldingM.isPending &&
                          addHoldingM.variables?.ticker === a.ticker
                        }
                        onAdd={() => {
                          setCarteiraErro(null);
                          void addHoldingM.mutateAsync(a);
                        }}
                      />
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </CardContent>
        </Card>
      ) : null}

      {report && report.ativos.length === 0 ? (
        <p className="text-sm text-muted-foreground">
          Nenhum ativo com posição calculada. Verifique se a planilha contém
          linhas de compra/venda ou transferência de renda variável.
        </p>
      ) : null}
    </div>
  );
}
