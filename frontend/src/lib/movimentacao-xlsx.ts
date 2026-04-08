import * as XLSX from "xlsx";
import type { MovimentacaoRow } from "@/lib/movimentacao-types";
import { parsePlanilhaNumero } from "@/lib/movimentacao-preco-medio";

function normalizeHeaderCell(raw: unknown): string {
  return String(raw ?? "")
    .trim()
    .toLowerCase()
    .normalize("NFD")
    .replace(/\p{M}/gu, "");
}

/** Mapa de cabeçalhos comuns (sem acentos) → campo. */
const HEADER_TO_FIELD: Record<string, keyof MovimentacaoRow> = {
  "entrada/saida": "entradaSaida",
  "movimentacao": "movimentacao",
  data: "data",
  produto: "produto",
  quantidade: "quantidade",
  "preco unitario": "precoUnitario",
  "valor da operacao": "valorOperacao",
};

function headerToField(header: string): keyof MovimentacaoRow | null {
  const n = normalizeHeaderCell(header);
  return HEADER_TO_FIELD[n] ?? null;
}

export class MovimentacaoPlanilhaError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "MovimentacaoPlanilhaError";
  }
}

/**
 * Lê a primeira aba de um .xlsx de movimentação (ex.: BTG) e devolve linhas tipadas.
 */
export function parseMovimentacaoXlsx(input: ArrayBuffer | Uint8Array): MovimentacaoRow[] {
  const ab =
    input instanceof Uint8Array
      ? input.buffer.slice(input.byteOffset, input.byteOffset + input.byteLength)
      : input;
  const wb = XLSX.read(ab, { type: "array", cellDates: false });
  const sheetName = wb.SheetNames[0];
  if (!sheetName) {
    throw new MovimentacaoPlanilhaError(
      "Nenhuma aba encontrada no arquivo. Envie uma planilha .xlsx válida.",
    );
  }
  const sheet = wb.Sheets[sheetName];
  const matrix = XLSX.utils.sheet_to_json<(string | number | null | undefined)[]>(
    sheet,
    { header: 1, defval: null, raw: false },
  );

  if (!matrix.length) {
    throw new MovimentacaoPlanilhaError(
      "A planilha está vazia. Use o export de movimentação da corretora.",
    );
  }

  const headerRow = matrix[0] ?? [];
  const colByField = new Map<keyof MovimentacaoRow, number>();
  headerRow.forEach((cell, colIndex) => {
    const field = headerToField(String(cell ?? ""));
    if (field) colByField.set(field, colIndex);
  });

  const required: (keyof MovimentacaoRow)[] = [
    "entradaSaida",
    "data",
    "movimentacao",
    "produto",
    "quantidade",
  ];
  for (const key of required) {
    if (!colByField.has(key)) {
      throw new MovimentacaoPlanilhaError(
        `Cabeçalho obrigatório ausente: "${key}". A primeira linha deve listar Entrada/Saída, Data, Movimentação, Produto e Quantidade (e opcionalmente Preço unitário e Valor da Operação).`,
      );
    }
  }

  const out: MovimentacaoRow[] = [];

  for (let r = 1; r < matrix.length; r++) {
    const line = matrix[r];
    if (!line || !line.length) continue;
    const pick = (k: keyof MovimentacaoRow): unknown => {
      const c = colByField.get(k);
      return c !== undefined ? line[c] : undefined;
    };

    const produto = String(pick("produto") ?? "").trim();
    if (!produto) continue;

    const entradaSaida = String(pick("entradaSaida") ?? "").trim();
    const data = String(pick("data") ?? "").trim();
    const movimentacao = String(pick("movimentacao") ?? "").trim();

    const qRaw = pick("quantidade");
    const qty = parsePlanilhaNumero(qRaw);
    if (qty === null || qty < 0) continue;

    const precoRaw = colByField.has("precoUnitario")
      ? pick("precoUnitario")
      : undefined;
    const valorRaw = colByField.has("valorOperacao")
      ? pick("valorOperacao")
      : undefined;

    const precoUnitario = parsePlanilhaNumero(precoRaw);
    const valorOperacao = parsePlanilhaNumero(valorRaw);

    out.push({
      entradaSaida,
      data,
      movimentacao,
      produto,
      quantidade: qty,
      precoUnitario,
      valorOperacao,
    });
  }

  if (out.length === 0) {
    throw new MovimentacaoPlanilhaError(
      "Nenhuma linha de dados encontrada após o cabeçalho.",
    );
  }

  return out;
}
