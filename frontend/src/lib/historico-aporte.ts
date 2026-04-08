/** Origem inferida pela observação (calculadora grava texto padrão). */
export type AporteOrigem = "manual" | "calculadora";

export function classifyAporteNote(note: string | null): AporteOrigem {
  const n = (note ?? "").toLowerCase();
  if (n.includes("calculadora")) return "calculadora";
  return "manual";
}

export type HistoricoFiltroOrigem = "todos" | AporteOrigem;
