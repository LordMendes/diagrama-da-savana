import { describe, expect, it } from "vitest";
import { classifyAporteNote } from "@/lib/historico-aporte";

describe("classifyAporteNote", () => {
  it("detecta aplicação da calculadora", () => {
    expect(classifyAporteNote("Calculadora de aporte")).toBe("calculadora");
  });

  it("trata manual quando não há calculadora na observação", () => {
    expect(classifyAporteNote("Aporte mensal")).toBe("manual");
    expect(classifyAporteNote(null)).toBe("manual");
  });
});
