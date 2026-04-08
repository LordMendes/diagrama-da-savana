const ACCESS = "diagrama_savana_access_token";
const RENEWAL = "diagrama_savana_renewal_token";

export type StoredTokens = {
  accessToken: string;
  renewalToken: string;
};

export function loadTokens(): StoredTokens | null {
  try {
    const accessToken = localStorage.getItem(ACCESS);
    const renewalToken = localStorage.getItem(RENEWAL);
    if (!accessToken || !renewalToken) {
      return null;
    }
    return { accessToken, renewalToken };
  } catch {
    return null;
  }
}

export function saveTokens(tokens: StoredTokens): void {
  localStorage.setItem(ACCESS, tokens.accessToken);
  localStorage.setItem(RENEWAL, tokens.renewalToken);
}

export function clearTokens(): void {
  localStorage.removeItem(ACCESS);
  localStorage.removeItem(RENEWAL);
}
