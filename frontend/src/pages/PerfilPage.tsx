import { useMutation } from "@tanstack/react-query";
import { useEffect, useState } from "react";
import { useAuth } from "@/auth/auth-context";
import { updateMe } from "@/api/me";
import { ApiError } from "@/lib/api";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

export function PerfilPage() {
  const { user, getAccessToken, signOut, refreshProfile } = useAuth();
  const [email, setEmail] = useState(user?.email ?? "");
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    setEmail(user?.email ?? "");
  }, [user?.email]);

  const saveM = useMutation({
    mutationFn: async () => {
      const t = getAccessToken();
      if (!t) throw new Error("Sessão expirada.");
      return updateMe(t, email.trim());
    },
    onSuccess: async () => {
      setError(null);
      setMessage("Dados atualizados.");
      await refreshProfile();
    },
    onError: (e: unknown) => {
      setMessage(null);
      if (e instanceof ApiError) {
        const fields = e.fields as Record<string, string[]> | undefined;
        const emailErr = fields?.email?.[0];
        setError(emailErr ?? e.message);
        return;
      }
      setError("Não foi possível salvar. Tente novamente.");
    },
  });

  return (
    <div className="flex flex-1 flex-col gap-8">
      <div>
        <h1 className="text-2xl font-semibold tracking-tight text-foreground">
          Perfil
        </h1>
        <p className="mt-1 text-sm text-muted-foreground">
          Dados da conta e encerramento de sessão.
        </p>
      </div>

      <Card className="max-w-md">
        <CardHeader>
          <CardTitle className="text-base">E-mail</CardTitle>
        </CardHeader>
        <CardContent className="flex flex-col gap-4">
          <div className="space-y-2">
            <Label htmlFor="perfil-email">E-mail</Label>
            <Input
              id="perfil-email"
              type="email"
              autoComplete="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
            />
          </div>
          {error && (
            <p className="text-sm text-destructive" role="alert">
              {error}
            </p>
          )}
          {message && (
            <p className="text-sm text-emerald-700 dark:text-emerald-400">
              {message}
            </p>
          )}
          <Button
            type="button"
            disabled={saveM.isPending || email.trim() === (user?.email ?? "")}
            onClick={() => {
              setMessage(null);
              setError(null);
              saveM.mutate();
            }}
          >
            {saveM.isPending ? "Salvando…" : "Salvar alterações"}
          </Button>
        </CardContent>
      </Card>

      <Card className="max-w-md border-destructive/30">
        <CardHeader>
          <CardTitle className="text-base">Sessão</CardTitle>
        </CardHeader>
        <CardContent>
          <p className="mb-4 text-sm text-muted-foreground">
            Encerra a sessão neste dispositivo. Você precisará entrar de novo
            para acessar o app.
          </p>
          <Button
            type="button"
            variant="destructive"
            onClick={() => void signOut()}
          >
            Sair da conta
          </Button>
        </CardContent>
      </Card>
    </div>
  );
}
