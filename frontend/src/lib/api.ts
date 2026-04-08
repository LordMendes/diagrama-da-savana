import { getApiBaseUrl } from "@/lib/env";

/** Monta URL absoluta para a API (path começando com `/`). */
export function apiUrl(path: string): string {
  const base = getApiBaseUrl();
  const p = path.startsWith("/") ? path : `/${path}`;
  if (!base) {
    return p;
  }
  return `${base.replace(/\/$/, "")}${p}`;
}

export class ApiError extends Error {
  readonly status: number;
  readonly code?: string;
  readonly fields?: Record<string, string[]>;

  constructor(
    message: string,
    status: number,
    options?: { code?: string; fields?: Record<string, string[]> },
  ) {
    super(message);
    this.name = "ApiError";
    this.status = status;
    this.code = options?.code;
    this.fields = options?.fields;
  }
}

type ApiRequestOptions = {
  method?: string;
  json?: unknown;
  /** Access token JWT (Authorization: Bearer …). */
  token?: string | null;
};

export async function apiRequest<T>(
  path: string,
  opts: ApiRequestOptions = {},
): Promise<T> {
  const url = apiUrl(path);
  const headers: Record<string, string> = {
    Accept: "application/json",
  };
  if (opts.json !== undefined) {
    headers["Content-Type"] = "application/json";
  }
  if (opts.token) {
    headers["Authorization"] = `Bearer ${opts.token}`;
  }

  const res = await fetch(url, {
    method: opts.method ?? "GET",
    headers,
    body: opts.json !== undefined ? JSON.stringify(opts.json) : undefined,
  });

  const text = await res.text();
  let body: unknown = null;
  if (text) {
    try {
      body = JSON.parse(text) as unknown;
    } catch {
      body = null;
    }
  }

  if (!res.ok) {
    const err = body as
      | {
          error?: {
            message?: string;
            code?: string;
            fields?: Record<string, string[]>;
          };
          errors?: Record<string, string[]>;
        }
      | null;
    const fields = err?.error?.fields ?? err?.errors;
    const message =
      err?.error?.message ??
      (err?.errors && Object.keys(err.errors).length > 0
        ? "Verifique os campos destacados."
        : null) ??
      res.statusText ??
      "Erro na requisição";
    throw new ApiError(message, res.status, {
      code: err?.error?.code,
      fields,
    });
  }

  return body as T;
}
