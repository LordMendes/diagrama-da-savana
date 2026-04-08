import { useMutation } from "@tanstack/react-query";
import { useId, useState } from "react";
import { Link, useLocation, useNavigate } from "react-router-dom";
import { useAuth } from "@/auth/auth-context";
import { AuthPageShell } from "@/components/auth/AuthPageShell";
import { FieldMessages } from "@/components/auth/FieldMessages";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { ApiError } from "@/lib/api";

export function LoginPage() {
  const emailId = useId();
  const passwordId = useId();
  const { signIn } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const from =
    (location.state as { from?: { pathname?: string } } | undefined)?.from
      ?.pathname ?? "/app";

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");

  const mutation = useMutation({
    mutationFn: () => signIn(email.trim(), password),
    onSuccess: () => navigate(from, { replace: true }),
  });

  const apiError = mutation.error instanceof ApiError ? mutation.error : null;
  const genericMessage =
    mutation.error && !apiError
      ? mutation.error instanceof Error
        ? mutation.error.message
        : "Não foi possível entrar."
      : null;

  return (
    <AuthPageShell
      title="Entrar"
      description="Acesse sua conta com e-mail e senha."
      footer={
        <>
          Não tem conta?{" "}
          <Link
            to="/cadastro"
            className="font-medium text-primary underline-offset-4 hover:underline"
          >
            Cadastre-se
          </Link>
        </>
      }
    >
      <Card>
        <CardHeader>
          <CardTitle>Login</CardTitle>
          <CardDescription>
            Use o mesmo e-mail cadastrado no Diagrama da Savana.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <form
            className="space-y-4"
            onSubmit={(e) => {
              e.preventDefault();
              mutation.mutate();
            }}
            noValidate
          >
            {(apiError && !apiError.fields) || genericMessage ? (
              <p
                className="rounded-md border border-destructive/40 bg-destructive/10 px-3 py-2 text-sm text-destructive"
                role="alert"
              >
                {genericMessage ?? apiError?.message}
              </p>
            ) : null}

            <div className="space-y-2">
              <Label htmlFor={emailId}>E-mail</Label>
              <Input
                id={emailId}
                name="email"
                type="email"
                autoComplete="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                aria-invalid={Boolean(apiError?.fields?.email)}
              />
              <FieldMessages messages={apiError?.fields?.email} />
            </div>

            <div className="space-y-2">
              <div className="flex items-center justify-between gap-2">
                <Label htmlFor={passwordId}>Senha</Label>
                <Link
                  to="/esqueci-senha"
                  className="text-xs font-medium text-primary underline-offset-4 hover:underline"
                >
                  Esqueci minha senha
                </Link>
              </div>
              <Input
                id={passwordId}
                name="password"
                type="password"
                autoComplete="current-password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                aria-invalid={Boolean(apiError?.fields?.password)}
              />
              <FieldMessages messages={apiError?.fields?.password} />
            </div>

            <Button
              type="submit"
              className="w-full"
              disabled={mutation.isPending}
            >
              {mutation.isPending ? "Entrando…" : "Entrar"}
            </Button>
          </form>
        </CardContent>
      </Card>
    </AuthPageShell>
  );
}
