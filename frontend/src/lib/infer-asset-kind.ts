/**
 * Heurística B3: muitos FIIs terminam em 11; demais tratamos como ação.
 * O usuário pode ajustar a classe em Carteira se necessário.
 */
export function inferAssetKindFromTicker(ticker: string): string {
  const t = ticker.trim().toUpperCase();
  if (t.length >= 5 && t.endsWith("11")) return "fii";
  return "acao";
}
