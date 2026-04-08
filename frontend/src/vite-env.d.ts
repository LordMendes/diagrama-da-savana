/// <reference types="vite/client" />

interface ImportMetaEnv {
  /**
   * Público: URL base da API Phoenix.
   * Vazio = mesmo origin (proxy `/api` no Vite em dev). Ver `frontend/.env.example`.
   */
  readonly VITE_API_BASE_URL?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
