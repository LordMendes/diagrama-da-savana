import { describe, expect, it, vi } from "vitest";
import { ApiError, apiRequest } from "./api";

describe("apiRequest", () => {
  it("lança ApiError com fields quando a API devolve validação", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue({
        ok: false,
        status: 422,
        text: () =>
          Promise.resolve(
            JSON.stringify({
              error: {
                code: "validacao_falhou",
                message: "Não foi possível criar a conta.",
                fields: { email: ["já está em uso"] },
              },
            }),
          ),
      }),
    );

    await expect(
      apiRequest("/api/v1/registration", {
        method: "POST",
        json: { user: {} },
      }),
    ).rejects.toMatchObject({
      name: "ApiError",
      message: "Não foi possível criar a conta.",
      code: "validacao_falhou",
      fields: { email: ["já está em uso"] },
    });

    vi.unstubAllGlobals();
  });

  it("lança ApiError com fields a partir de errors (changeset Phoenix)", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue({
        ok: false,
        status: 422,
        text: () =>
          Promise.resolve(
            JSON.stringify({
              errors: { amount: ["deve ser maior que zero"] },
            }),
          ),
      }),
    );

    await expect(apiRequest("/api/v1/x")).rejects.toMatchObject({
      name: "ApiError",
      message: "Verifique os campos destacados.",
      fields: { amount: ["deve ser maior que zero"] },
    });

    vi.unstubAllGlobals();
  });

  it("usa mensagem genérica quando o corpo não é JSON de erro", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue({
        ok: false,
        status: 502,
        text: () => Promise.resolve("bad gateway"),
      }),
    );

    try {
      await apiRequest("/api/v1/x");
      expect.fail("deveria lançar");
    } catch (e) {
      expect(e).toBeInstanceOf(ApiError);
      expect((e as ApiError).status).toBe(502);
    }

    vi.unstubAllGlobals();
  });
});
