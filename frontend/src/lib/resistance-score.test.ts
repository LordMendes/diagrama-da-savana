import { describe, expect, it } from "vitest";
import { clampResistanceScore, previewScore } from "./resistance-score";

describe("resistance-score", () => {
  it("clamp alinha ao backend", () => {
    expect(clampResistanceScore(100)).toBe(10);
    expect(clampResistanceScore(-100)).toBe(-5);
    expect(clampResistanceScore(3)).toBe(3);
  });

  it("previewScore soma e limita", () => {
    const m: Record<string, number> = {
      a: 1,
      b: 1,
      c: -1,
    };
    expect(previewScore(m)).toBe(1);
  });
});
