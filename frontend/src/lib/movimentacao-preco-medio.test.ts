import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { describe, expect, it } from "vitest";
import { computePrecoMedioPorAtivo, extrairTicker, parsePlanilhaNumero } from "@/lib/movimentacao-preco-medio";
import type { MovimentacaoRow } from "@/lib/movimentacao-types";
import { parseMovimentacaoXlsx } from "@/lib/movimentacao-xlsx";

const __dirname = dirname(fileURLToPath(import.meta.url));

describe("parsePlanilhaNumero", () => {
  it("aceita vírgula decimal", () => {
    expect(parsePlanilhaNumero("83,09")).toBeCloseTo(83.09);
  });
  it("aceita número nativo", () => {
    expect(parsePlanilhaNumero(300)).toBe(300);
  });
  it("retorna null para traço", () => {
    expect(parsePlanilhaNumero("-")).toBeNull();
  });
});

describe("extrairTicker", () => {
  it("lê ticker antes do hífen", () => {
    expect(extrairTicker("VALE3 - VALE S.A.")).toBe("VALE3");
    expect(extrairTicker("XPML11 - XP MALLS")).toBe("XPML11");
  });
});

describe("computePrecoMedioPorAtivo", () => {
  it("compra e venda simples com preço médio conhecido", () => {
    const rows: MovimentacaoRow[] = [
      {
        entradaSaida: "Credito",
        data: "01/01/2026",
        movimentacao: "Transferência - Liquidação",
        produto: "PETR4 - PETROBRAS",
        quantidade: 100,
        precoUnitario: 30,
        valorOperacao: 3000,
      },
      {
        entradaSaida: "Debito",
        data: "02/01/2026",
        movimentacao: "Transferência - Liquidação",
        produto: "PETR4 - PETROBRAS",
        quantidade: 40,
        precoUnitario: 35,
        valorOperacao: 1400,
      },
    ];
    const { ativos } = computePrecoMedioPorAtivo(rows);
    const p = ativos.find((a) => a.ticker === "PETR4");
    expect(p?.quantidade).toBe(60);
    expect(p?.custoTotal).toBeCloseTo(1800, 1);
    expect(p?.precoMedio).toBeCloseTo(30, 5);
  });

  it("integração: fixture BTG de movimentação", () => {
    const buf = readFileSync(
      join(__dirname, "../../test/fixtures/movimentacao-sample.xlsx"),
    );
    const rows = parseMovimentacaoXlsx(buf);
    const { ativos } = computePrecoMedioPorAtivo(rows);
    const by = Object.fromEntries(ativos.map((a) => [a.ticker, a]));
    expect(by.VALE3?.quantidade).toBeGreaterThanOrEqual(0);
    expect(by.WEGE3?.quantidade).toBeGreaterThanOrEqual(0);
    expect(ativos.length).toBeGreaterThan(0);
  });
});
