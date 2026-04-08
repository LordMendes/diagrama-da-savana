import { describe, expect, it } from "vitest";
import { inferAssetKindFromTicker } from "@/lib/infer-asset-kind";

describe("inferAssetKindFromTicker", () => {
  it("classifica sufixo 11 longo como FII", () => {
    expect(inferAssetKindFromTicker("XPML11")).toBe("fii");
  });
  it("classifica ações ordinárias como ação", () => {
    expect(inferAssetKindFromTicker("VALE3")).toBe("acao");
  });
});
