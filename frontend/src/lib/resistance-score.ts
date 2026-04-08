/** Alinhado ao backend: soma dos critérios com limite -5..+10. */

export function clampResistanceScore(raw: number): number {
  return Math.max(-5, Math.min(10, Math.trunc(raw)));
}

export function sumCriteriaValues(criteria: Record<string, number>): number {
  return Object.values(criteria).reduce((a, b) => a + b, 0);
}

export function previewScore(criteria: Record<string, number>): number {
  return clampResistanceScore(sumCriteriaValues(criteria));
}
