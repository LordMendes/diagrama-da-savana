import { apiRequest } from "@/lib/api";

export type ResistanceCriterion = { id: string; label: string };

export type ResistanceProfileRow = {
  id: string;
  asset_id: string;
  computed_score: number | null;
  criteria: Record<string, number>;
  eligible_for_allocation: boolean;
  asset: {
    id: string;
    ticker: string;
    kind: string;
  } | null;
  inserted_at: string;
  updated_at: string;
};

export async function fetchResistanceCriteria(
  kind: "acao" | "fii" | "cripto",
  token: string,
) {
  const qs = new URLSearchParams({ kind });
  return apiRequest<{ data: ResistanceCriterion[] }>(
    `/api/v1/resistance_criteria?${qs.toString()}`,
    { token },
  );
}

export async function fetchResistanceProfiles(token: string) {
  return apiRequest<{ data: ResistanceProfileRow[] }>(
    "/api/v1/resistance_profiles",
    { token },
  );
}

export async function fetchResistanceProfile(assetId: string, token: string) {
  return apiRequest<{ data: ResistanceProfileRow }>(
    `/api/v1/resistance_profiles/${assetId}`,
    { token },
  );
}

export async function upsertResistanceProfile(
  assetId: string,
  criteria: Record<string, number>,
  token: string,
) {
  return apiRequest<{ data: ResistanceProfileRow }>(
    `/api/v1/resistance_profiles/${assetId}`,
    {
      method: "PUT",
      token,
      json: { resistance_profile: { criteria } },
    },
  );
}
