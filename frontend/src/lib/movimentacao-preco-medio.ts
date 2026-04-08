import type {
  AtivoPrecoMedioResult,
  MovimentacaoPrecoMedioReport,
  MovimentacaoRow,
} from "@/lib/movimentacao-types";

type Position = { qty: number; cost: number; produtoLabel: string };

/** Parse número vindo da planilha (pt-BR ou float Excel). */
export function parsePlanilhaNumero(raw: unknown): number | null {
  if (raw === null || raw === undefined) return null;
  if (typeof raw === "number" && Number.isFinite(raw)) return raw;
  const s = String(raw).trim();
  if (s === "" || s === "-" || s === "—") return null;
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
  return Number.isFinite(n) ? n : null;
}

function parseDataBrParaMs(data: string): number {
  const m = data.trim().match(/^(\d{1,2})\/(\d{1,2})\/(\d{4})$/);
  if (!m) return 0;
  const d = Number(m[1]);
  const mo = Number(m[2]);
  const y = Number(m[3]);
  return new Date(y, mo - 1, d).getTime();
}

function normalizeEntrada(raw: string): "Credito" | "Debito" | "other" {
  const s = raw.trim().toLowerCase();
  if (s.startsWith("cred")) return "Credito";
  if (s.startsWith("deb")) return "Debito";
  return "other";
}

function isRendaFixaProduto(produto: string): boolean {
  const p = produto.trim().toUpperCase();
  return (
    /^CDB\b/.test(p) ||
    /^LCI\b/.test(p) ||
    /^LCA\b/.test(p) ||
    /^TESOURO\b/.test(p) ||
    /^LF\b/.test(p)
  );
}

/** Extrai ticker B3 (primeiro token antes de " - "). */
export function extrairTicker(produto: string): string | null {
  const trimmed = produto.trim();
  const match = trimmed.match(/^([A-Z0-9]{4,12})\s*-\s*/i);
  return match ? match[1].toUpperCase() : null;
}

function movimentacaoIgnorada(mov: string): boolean {
  const m = mov.toLowerCase().trim();
  if (m.includes("empréstimo")) return true;
  if (m.includes("juros sobre capital")) return true;
  if (m.startsWith("rendimento")) return true;
  if (m === "dividendo" || m.includes("dividendo")) return true;
  if (m.includes("vencimento")) return true;
  if (m.includes("aplicaç") || m === "aplicação") return true;
  if (m.includes("subscrição") || m.includes("subscricao")) return true;
  if (m.includes("cessão") || m.includes("cessao")) return true;
  if (m.includes("desdobro") || m.includes("grupamento") || m.includes("cisão") || m.includes("cisao"))
    return true;
  if (m.includes("atualização") && m.includes("ativo")) return true;
  return false;
}

function inferirPrecoUnitario(row: MovimentacaoRow): number | null {
  if (row.precoUnitario !== null && row.precoUnitario > 0) return row.precoUnitario;
  if (
    row.valorOperacao !== null &&
    row.quantidade > 0 &&
    row.valorOperacao > 0
  ) {
    return row.valorOperacao / row.quantidade;
  }
  return null;
}

type Efeito =
  | { tag: "buy"; qty: number; unit: number }
  | { tag: "sell"; qty: number }
  | { tag: "transfer_in"; qty: number }
  | { tag: "transfer_out"; qty: number }
  | { tag: "skip" };

function classificarEfeito(row: MovimentacaoRow): Efeito {
  const mov = row.movimentacao.trim();
  const movL = mov.toLowerCase();
  const entrada = normalizeEntrada(row.entradaSaida);
  const qty = row.quantidade;

  if (entrada === "other" || qty <= 0) return { tag: "skip" };

  const isLiquidação = movL.includes("liquidação") || movL.includes("liquidacao");
  const isSóTransferencia =
    movL.includes("transferência") || movL.includes("transferencia");
  const unit = inferirPrecoUnitario(row);
  const hasPrice = unit !== null && unit > 0;

  if (isLiquidação && isSóTransferencia) {
    if (hasPrice) {
      if (entrada === "Credito") return { tag: "buy", qty, unit: unit! };
      return { tag: "sell", qty };
    }
    /* Liquidação sem preço na planilha: venda/compra ainda altera posição — usa PM para saída. */
    if (entrada === "Debito") return { tag: "sell", qty };
    if (entrada === "Credito") return { tag: "transfer_in", qty };
    return { tag: "skip" };
  }

  if (movL === "venda" || movL.includes("venda -")) {
    return { tag: "sell", qty };
  }

  if (movL === "compra" || (movL.includes("compra") && !movL.includes("venda"))) {
    if (hasPrice && entrada === "Credito") return { tag: "buy", qty, unit: unit! };
    return { tag: "skip" };
  }

  if (movL.includes("compra") && movL.includes("venda")) {
    if (entrada === "Credito" && hasPrice) return { tag: "buy", qty, unit: unit! };
    if (entrada === "Debito") return { tag: "sell", qty };
    return { tag: "skip" };
  }

  if (isSóTransferencia && !isLiquidação) {
    if (entrada === "Credito") return { tag: "transfer_in", qty };
    if (entrada === "Debito") return { tag: "transfer_out", qty };
  }

  if (hasPrice) {
    if (entrada === "Credito") return { tag: "buy", qty, unit: unit! };
    if (entrada === "Debito") return { tag: "sell", qty };
  }

  return { tag: "skip" };
}

function aplicarEfeito(pos: Position, e: Efeito, avisos: string[], ticker: string): void {
  const avg = pos.qty > 0 ? pos.cost / pos.qty : 0;

  switch (e.tag) {
    case "buy": {
      pos.qty += e.qty;
      pos.cost += e.qty * e.unit;
      break;
    }
    case "sell": {
      const q = Math.min(e.qty, pos.qty);
      if (e.qty > pos.qty + 1e-9) {
        avisos.push(
          `${ticker}: venda de ${e.qty} com posição ${pos.qty.toFixed(4)} — ajustado ao disponível.`,
        );
      }
      pos.cost -= q * avg;
      pos.qty -= q;
      break;
    }
    case "transfer_in": {
      pos.qty += e.qty;
      pos.cost += e.qty * avg;
      break;
    }
    case "transfer_out": {
      const q = Math.min(e.qty, pos.qty);
      if (e.qty > pos.qty + 1e-9) {
        avisos.push(
          `${ticker}: transferência de saída ${e.qty} com posição ${pos.qty.toFixed(4)} — ajustado.`,
        );
      }
      pos.cost -= q * avg;
      pos.qty -= q;
      break;
    }
    default:
      break;
  }

  if (pos.qty <= 1e-12) {
    pos.qty = 0;
    pos.cost = 0;
  }
}

/**
 * Calcula preço médio de custo e quantidade por ativo a partir de linhas de movimentação.
 * Linhas são ordenadas por data (asc); eventos corporativos complexos podem ser ignorados (avisos).
 */
export function computePrecoMedioPorAtivo(
  rows: MovimentacaoRow[],
): MovimentacaoPrecoMedioReport {
  const avisos: string[] = [];
  const indexed = rows.map((row, index) => ({ row, index }));

  indexed.sort((a, b) => {
    const ta = parseDataBrParaMs(a.row.data);
    const tb = parseDataBrParaMs(b.row.data);
    if (ta !== tb) return ta - tb;
    return a.index - b.index;
  });

  const byTicker = new Map<string, Position>();

  for (const { row } of indexed) {
    const produto = row.produto.trim();
    if (!produto || isRendaFixaProduto(produto)) continue;

    const ticker = extrairTicker(produto);
    if (!ticker) {
      avisos.push(
        `Produto sem ticker reconhecido: "${produto.length > 48 ? `${produto.slice(0, 48)}…` : produto}".`,
      );
      continue;
    }

    if (movimentacaoIgnorada(row.movimentacao)) continue;

    let pos = byTicker.get(ticker);
    if (!pos) {
      pos = { qty: 0, cost: 0, produtoLabel: produto };
      byTicker.set(ticker, pos);
    }

    const efeito = classificarEfeito(row);
    if (efeito.tag === "skip") continue;

    if (efeito.tag === "transfer_in" && pos.qty <= 0) {
      avisos.push(
        `${ticker}: transferência de entrada sem posição prévia — custo assumido 0 (ajuste manual se necessário).`,
      );
    }

    aplicarEfeito(pos, efeito, avisos, ticker);
  }

  const ativos: AtivoPrecoMedioResult[] = [...byTicker.entries()].map(
    ([ticker, pos]) => {
      const q = roundQty(pos.qty);
      const cost = roundMoney(pos.cost);
      const precoMedio = q > 0 ? roundMoney(cost / q) : null;
      return {
        ticker,
        produtoLabel: pos.produtoLabel,
        quantidade: q,
        custoTotal: cost,
        precoMedio,
      };
    },
  );

  ativos.sort((a, b) => a.ticker.localeCompare(b.ticker));

  return { ativos, avisos };
}

function roundQty(n: number): number {
  return Math.round(n * 1e8) / 1e8;
}

function roundMoney(n: number): number {
  return Math.round(n * 100) / 100;
}
