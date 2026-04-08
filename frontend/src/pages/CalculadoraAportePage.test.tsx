import * as CarteiraApi from "@/api/carteira";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi, afterEach, beforeEach } from "vitest";
import { MemoryRouter } from "react-router-dom";
import { CalculadoraAportePage } from "./CalculadoraAportePage";

vi.mock("@/auth/auth-context", () => ({
  useAuth: () => ({
    getAccessToken: () => "test-token",
    user: { email: "t@example.com" },
    signOut: vi.fn(),
  }),
}));

describe("CalculadoraAportePage", () => {
  beforeEach(() => {
    vi.spyOn(CarteiraApi, "fetchPortfolios").mockResolvedValue({
      data: [
        {
          id: "portfolio-1",
          name: "Principal",
          inserted_at: "",
          updated_at: "",
        },
      ],
    });
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it("renderiza título e formulário", async () => {
    const client = new QueryClient({
      defaultOptions: { queries: { retry: false } },
    });

    render(
      <QueryClientProvider client={client}>
        <MemoryRouter>
          <CalculadoraAportePage />
        </MemoryRouter>
      </QueryClientProvider>,
    );

    expect(
      await screen.findByRole("heading", { name: /calculadora de aporte/i }),
    ).toBeInTheDocument();
    expect(await screen.findByLabelText(/valor do aporte/i)).toBeInTheDocument();
    expect(
      screen.getByRole("button", { name: /calcular/i }),
    ).toBeInTheDocument();
  });
});
