import { apiRequest } from "@/lib/api";

export async function updateMe(token: string, email: string) {
  return apiRequest<{ data: { id: string; email: string } }>("/api/v1/me", {
    method: "PATCH",
    token,
    json: { user: { email } },
  });
}
