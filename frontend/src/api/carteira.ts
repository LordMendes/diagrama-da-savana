import { apiRequest } from "@/lib/api";

export type Portfolio = {
  id: string;
  name: string;
  inserted_at: string;
  updated_at: string;
};

export type TargetAllocation = {
  id: string;
  macro_class: string;
  target_percent: string;
  inserted_at: string;
  updated_at: string;
};

export type Holding = {
  id: string;
  quantity: string;
  average_price: string;
  asset: {
    id: string;
    ticker: string;
    kind: string;
  } | null;
  inserted_at: string;
  updated_at: string;
};

export type AllocationMacroRow = {
  macro_class: string;
  current_percent: string;
  target_percent: string | null;
};

export type AporteRow = {
  id: string;
  amount: string;
  note: string | null;
  occurred_on: string;
  inserted_at: string;
  updated_at: string;
};

export type PortfolioSummary = {
  portfolio: Portfolio;
  total_value: string;
  daily_change_percent: string | null;
  quotes_partial: boolean;
  allocation_by_macro: AllocationMacroRow[];
  recent_aportes: AporteRow[];
};

export async function fetchPortfolios(token: string) {
  return apiRequest<{ data: Portfolio[] }>("/api/v1/portfolios", { token });
}

export async function fetchPortfolioSummary(portfolioId: string, token: string) {
  return apiRequest<{ data: PortfolioSummary }>(
    `/api/v1/portfolios/${portfolioId}/summary`,
    { token },
  );
}

export async function fetchTargetAllocations(portfolioId: string, token: string) {
  return apiRequest<{ data: TargetAllocation[] }>(
    `/api/v1/portfolios/${portfolioId}/target_allocations`,
    { token },
  );
}

export async function createTargetAllocation(
  portfolioId: string,
  body: { macro_class: string; target_percent: string },
  token: string,
) {
  return apiRequest<{ data: TargetAllocation }>(
    `/api/v1/portfolios/${portfolioId}/target_allocations`,
    {
      method: "POST",
      token,
      json: { target_allocation: body },
    },
  );
}

export async function updateTargetAllocation(
  portfolioId: string,
  id: string,
  body: { target_percent: string },
  token: string,
) {
  return apiRequest<{ data: TargetAllocation }>(
    `/api/v1/portfolios/${portfolioId}/target_allocations/${id}`,
    {
      method: "PATCH",
      token,
      json: { target_allocation: body },
    },
  );
}

export async function fetchHoldings(portfolioId: string, token: string) {
  return apiRequest<{ data: Holding[] }>(
    `/api/v1/portfolios/${portfolioId}/holdings`,
    { token },
  );
}

export async function createHolding(
  portfolioId: string,
  body: {
    ticker: string;
    kind: string;
    quantity: string;
    average_price: string;
  },
  token: string,
) {
  return apiRequest<{ data: Holding }>(
    `/api/v1/portfolios/${portfolioId}/holdings`,
    {
      method: "POST",
      token,
      json: { holding: body },
    },
  );
}

export async function deleteHolding(
  portfolioId: string,
  holdingId: string,
  token: string,
) {
  await apiRequest<unknown>(
    `/api/v1/portfolios/${portfolioId}/holdings/${holdingId}`,
    {
      method: "DELETE",
      token,
    },
  );
}

export async function fetchAportes(portfolioId: string, token: string) {
  return apiRequest<{ data: AporteRow[] }>(
    `/api/v1/portfolios/${portfolioId}/aportes`,
    { token },
  );
}

export async function createAporte(
  portfolioId: string,
  body: { amount: string; note?: string; occurred_on: string },
  token: string,
) {
  return apiRequest<{ data: AporteRow }>(
    `/api/v1/portfolios/${portfolioId}/aportes`,
    {
      method: "POST",
      token,
      json: { aporte: body },
    },
  );
}

export type MarketSearchHit = { ticker: string; name: string };

export async function searchMarketTickers(
  q: string,
  token: string,
): Promise<MarketSearchHit[]> {
  const qs = new URLSearchParams({ q });
  const res = await apiRequest<{ data: Record<string, unknown> }>(
    `/api/v1/market/search?${qs.toString()}`,
    { token },
  );
  const raw = res.data;
  const stocks = raw.stocks;
  if (!Array.isArray(stocks)) return [];

  const out: MarketSearchHit[] = [];
  const pushTicker = (ticker: string, name: string) => {
    const u = ticker.toUpperCase();
    if (out.some((x) => x.ticker === u)) return;
    out.push({ ticker: u, name });
  };

  for (const item of stocks) {
    if (typeof item === "string") {
      pushTicker(item, item);
      continue;
    }
    if (item && typeof item === "object") {
      const o = item as Record<string, unknown>;
      const t = o.stock ?? o.ticker ?? o.symbol;
      if (typeof t !== "string" || !t.trim()) continue;
      const name =
        (typeof o.name === "string" && o.name) ||
        (typeof o.shortName === "string" && o.shortName) ||
        (typeof o.short_name === "string" && o.short_name) ||
        t;
      pushTicker(t, name);
    }
  }

  const coins = raw.coins;
  if (Array.isArray(coins)) {
    for (const c of coins) {
      if (typeof c === "string" && c.trim()) pushTicker(c, c);
    }
  }

  return out;
}
