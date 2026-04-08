import { apiRequest } from "@/lib/api";

export type CatalogAsset = {
  id: string;
  ticker: string;
  kind: string;
  inserted_at: string;
  updated_at: string;
};

export async function fetchAssets(token: string) {
  return apiRequest<{ data: CatalogAsset[] }>("/api/v1/assets", { token });
}
