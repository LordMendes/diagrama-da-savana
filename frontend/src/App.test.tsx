import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { render, screen } from "@testing-library/react";
import type { ReactNode } from "react";
import { describe, expect, it } from "vitest";
import { BrowserRouter } from "react-router-dom";
import { AuthProvider } from "@/auth/auth-context";
import App from "./App";

function TestProviders({ children }: { children: ReactNode }) {
  const client = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  });
  return (
    <QueryClientProvider client={client}>
      <BrowserRouter>
        <AuthProvider>{children}</AuthProvider>
      </BrowserRouter>
    </QueryClientProvider>
  );
}

describe("App", () => {
  it("renderiza o título da aplicação", () => {
    render(<App />, { wrapper: TestProviders });
    expect(
      screen.getByRole("heading", { name: /diagrama da savana/i }),
    ).toBeInTheDocument();
  });
});
