import { useMutation } from "@tanstack/react-query";
import { useId, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { registerUser } from "@/api/auth";
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
import { useAuth } from "@/auth/auth-context";
import { ApiError } from "@/lib/api";

export function RegisterPage() {
  const emailId = useId();
  const passwordId = useId();
  const confirmId = useId();
  const navigate = useNavigate();
  const { setSession } = useAuth();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [passwordConfirmation, setPasswordConfirmation] = useState("");

  const mutation = useMutation({
    mutationFn: () =>
      registerUser({
        user: {
          email: email.trim(),
          password,
          password_confirmation: passwordConfirmation,
        },
      }),
    onSuccess: (res) => {
      const u = res.data.user;
      setSession({
        access_token: res.data.access_token,
        renewal_token: res.data.renewal_token,
        user: { id: String(u.id), email: u.email },
      });
      navigate("/app");
    },
  });

  const apiError = mutation.error instanceof ApiError ? mutation.error : null;

  return (
    <AuthPageShell
      title="Criar conta"
      description="Cadastre-se com e-mail e senha (mínimo 8 caracteres)."
      footer={
        <>
          Já tem conta?{" "}
          <Link
            to="/entrar"
            className="font-medium text-primary underline-offset-4 hover:underline"
          >
            Entrar
          </Link>
        </>
      }
    >
      <Card>
        <CardHeader>
          <CardTitle>Cadastro</CardTitle>
          <CardDescription>
            Após criar a conta você já fica autenticado neste dispositivo.
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
            {apiError && !apiError.fields ? (
              <p
                className="rounded-md border border-destructive/40 bg-destructive/10 px-3 py-2 text-sm text-destructive"
                role="alert"
              >
                {apiError.message}
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
              <Label htmlFor={passwordId}>Senha</Label>
              <Input
                id={passwordId}
                name="password"
                type="password"
                autoComplete="new-password"
                required
                minLength={8}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                aria-invalid={Boolean(apiError?.fields?.password)}
              />
              <FieldMessages messages={apiError?.fields?.password} />
            </div>

            <div className="space-y-2">
              <Label htmlFor={confirmId}>Confirmar senha</Label>
              <Input
                id={confirmId}
                name="password_confirmation"
                type="password"
                autoComplete="new-password"
                required
                value={passwordConfirmation}
                onChange={(e) => setPasswordConfirmation(e.target.value)}
                aria-invalid={Boolean(
                  apiError?.fields?.password_confirmation,
                )}
              />
              <FieldMessages
                messages={apiError?.fields?.password_confirmation}
              />
            </div>

            <Button
              type="submit"
              className="w-full"
              disabled={mutation.isPending}
            >
              {mutation.isPending ? "Criando conta…" : "Cadastrar"}
            </Button>
          </form>
        </CardContent>
      </Card>
    </AuthPageShell>
  );
}
