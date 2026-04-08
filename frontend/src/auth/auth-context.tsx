import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";
import type { AuthSuccess } from "@/api/auth";
import { ApiError, apiRequest, apiUrl } from "@/lib/api";
import {
  clearTokens as clearStored,
  loadTokens,
  saveTokens,
  type StoredTokens,
} from "@/lib/auth-storage";

export type AuthUser = {
  id: string;
  email: string;
};

type SessionPayload = {
  access_token: string;
  renewal_token: string;
  user: AuthUser;
};

type AuthContextValue = {
  user: AuthUser | null;
  isLoading: boolean;
  isAuthenticated: boolean;
  tokens: StoredTokens | null;
  signIn: (email: string, password: string) => Promise<void>;
  signOut: () => Promise<void>;
  /** Cadastro ou respostas que já trazem usuário + tokens. */
  setSession: (data: SessionPayload) => void;
  getAccessToken: () => string | null;
  /** Recarrega e-mail do usuário a partir de GET /api/v1/me. */
  refreshProfile: () => Promise<void>;
};

const AuthContext = createContext<AuthContextValue | null>(null);

async function fetchMe(
  accessToken: string,
): Promise<{ user: AuthUser } | { status: number }> {
  let res: Response;
  try {
    res = await fetch(apiUrl("/api/v1/me"), {
      headers: { Authorization: `Bearer ${accessToken}` },
    });
  } catch {
    return { status: 0 };
  }
  if (!res.ok) {
    return { status: res.status };
  }
  const body = (await res.json()) as { data: { id: string; email: string } };
  return {
    user: {
      id: String(body.data.id),
      email: body.data.email,
    },
  };
}

async function renewSession(
  renewalToken: string,
): Promise<{ access_token: string; renewal_token: string; user: AuthUser } | null> {
  const res = await fetch(apiUrl("/api/v1/session/renew"), {
    method: "POST",
    headers: {
      Authorization: `Bearer ${renewalToken}`,
      "Content-Type": "application/json",
    },
    body: "{}",
  });
  if (!res.ok) return null;
  const json = (await res.json()) as {
    data: { access_token: string; renewal_token: string };
  };
  const { access_token, renewal_token } = json.data;
  const me = await fetchMe(access_token);
  if (!("user" in me)) return null;
  return { access_token, renewal_token, user: me.user };
}

function toStored(p: SessionPayload): StoredTokens {
  return {
    accessToken: p.access_token,
    renewalToken: p.renewal_token,
  };
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [tokens, setTokensState] = useState<StoredTokens | null>(() =>
    loadTokens(),
  );
  const [user, setUser] = useState<AuthUser | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    function onStorage(e: StorageEvent) {
      if (e.key === null || e.key?.startsWith("diagrama_savana_")) {
        setTokensState(loadTokens());
      }
    }
    window.addEventListener("storage", onStorage);
    return () => window.removeEventListener("storage", onStorage);
  }, []);

  useEffect(() => {
    let cancelled = false;

    async function bootstrap() {
      if (!tokens) {
        setUser(null);
        setIsLoading(false);
        return;
      }

      const me = await fetchMe(tokens.accessToken);
      if (cancelled) return;

      if ("user" in me) {
        setUser(me.user);
        setIsLoading(false);
        return;
      }

      if (me.status !== 401) {
        setIsLoading(false);
        return;
      }

      const renewed = await renewSession(tokens.renewalToken);
      if (cancelled) return;

      if (renewed) {
        const next: StoredTokens = {
          accessToken: renewed.access_token,
          renewalToken: renewed.renewal_token,
        };
        saveTokens(next);
        setTokensState(next);
        setUser(renewed.user);
        setIsLoading(false);
        return;
      }

      clearStored();
      setTokensState(null);
      setUser(null);
      setIsLoading(false);
    }

    void bootstrap();
    return () => {
      cancelled = true;
    };
  }, [tokens]);

  const setSession = useCallback((data: SessionPayload) => {
    const stored = toStored(data);
    saveTokens(stored);
    setTokensState(stored);
    setUser(data.user);
  }, []);

  const signIn = useCallback(async (email: string, password: string) => {
    try {
      const json = await apiRequest<AuthSuccess>("/api/v1/session", {
        method: "POST",
        json: { user: { email, password } },
      });
      const u = json.data.user;
      setSession({
        access_token: json.data.access_token,
        renewal_token: json.data.renewal_token,
        user: { id: String(u.id), email: u.email },
      });
    } catch (e) {
      if (e instanceof ApiError) {
        throw e;
      }
      throw new Error("Não foi possível entrar. Tente novamente.");
    }
  }, [setSession]);

  const signOut = useCallback(async () => {
    const t = loadTokens();
    if (t) {
      try {
        await fetch(apiUrl("/api/v1/session"), {
          method: "DELETE",
          headers: { Authorization: `Bearer ${t.accessToken}` },
        });
      } catch {
        /* ignore */
      }
    }
    clearStored();
    setTokensState(null);
    setUser(null);
  }, []);

  const getAccessToken = useCallback(
    () => loadTokens()?.accessToken ?? null,
    [],
  );

  const refreshProfile = useCallback(async () => {
    const t = loadTokens()?.accessToken;
    if (!t) return;
    try {
      const json = await apiRequest<{ data: { id: string; email: string } }>(
        "/api/v1/me",
        { token: t },
      );
      setUser({ id: String(json.data.id), email: json.data.email });
    } catch {
      /* ignore */
    }
  }, []);

  const value = useMemo<AuthContextValue>(
    () => ({
      user,
      isLoading,
      isAuthenticated: user !== null,
      tokens,
      signIn,
      signOut,
      setSession,
      getAccessToken,
      refreshProfile,
    }),
    [user, isLoading, tokens, signIn, signOut, setSession, getAccessToken, refreshProfile],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) {
    throw new Error("useAuth deve ser usado dentro de AuthProvider");
  }
  return ctx;
}
