/**
 * Base URL da API Phoenix (sem barra final).
 * Vazio = mesma origem (requisições a `/api/...` passam pelo proxy do Vite em dev).
 * Defina `VITE_API_BASE_URL` se o build precisar chamar um host absoluto.
 */
export function getApiBaseUrl(): string {
  const raw = import.meta.env.VITE_API_BASE_URL;
  if (raw == null || raw === "") {
    return "";
  }
  return String(raw).replace(/\/$/, "");
}
