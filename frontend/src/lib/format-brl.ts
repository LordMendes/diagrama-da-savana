export function formatBrl(value: string | number): string {
  const n = typeof value === "string" ? Number(value.replace(",", ".")) : value;
  if (Number.isNaN(n)) return "—";
  return n.toLocaleString("pt-BR", { style: "currency", currency: "BRL" });
}

export function formatPercent(value: string | number | null | undefined): string {
  if (value === null || value === undefined) return "—";
  const n = typeof value === "string" ? Number(value.replace(",", ".")) : value;
  if (Number.isNaN(n)) return "—";
  return `${n >= 0 ? "+" : ""}${n.toLocaleString("pt-BR", {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  })}%`;
}
