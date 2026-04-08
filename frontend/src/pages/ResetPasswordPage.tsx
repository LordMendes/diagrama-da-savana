import { useMutation } from "@tanstack/react-query";
import { useId, useState } from "react";
import { Link, useSearchParams } from "react-router-dom";
import { resetPassword } from "@/api/auth";
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

export function ResetPasswordPage() {
  const [searchParams] = useSearchParams();
  const token = searchParams.get("token")?.trim() ?? "";
  const passwordId = useId();
  const confirmId = useId();

  const [password, setPassword] = useState("");
  const [passwordConfirmation, setPasswordConfirmation] = useState("");

  const mutation = useMutation({
    mutationFn: () =>
      resetPassword({
        token,
        password,
        password_confirmation: passwordConfirmation,
      }),
  });

  const apiError = mutation.error instanceof ApiError ? mutation.error : null;

  if (!token) {
    return (
      <AuthPageShell
        title="Link inválido"
        description="Não foi encontrado um token de redefinição na URL. Use o link enviado por e-mail."
        footer={
          <Link
            to="/esqueci-senha"
            className="font-medium text-primary underline-offset-4 hover:underline"
          >
            Solicitar novo link
          </Link>
        }
      >
        <Card>
          <CardContent className="pt-6">
            <p className="text-sm text-muted-foreground">
              O endereço deve ser algo como{" "}
              <code className="rounded bg-muted px-1 py-0.5 text-xs">
                /redefinir-senha?token=…
              </code>
              .
            </p>
          </CardContent>
        </Card>
      </AuthPageShell>
    );
  }

  if (mutation.isSuccess && mutation.data) {
    return (
      <AuthPageShell
        title="Senha atualizada"
        description={mutation.data.data.message}
        footer={
          <Link
            to="/entrar"
            className="font-medium text-primary underline-offset-4 hover:underline"
          >
            Ir para o login
          </Link>
        }
      >
        <Card>
          <CardHeader>
            <CardTitle>Tudo certo</CardTitle>
            <CardDescription>
              Você já pode entrar com a nova senha.
            </CardDescription>
          </CardHeader>
        </Card>
      </AuthPageShell>
    );
  }

  return (
    <AuthPageShell
      title="Redefinir senha"
      description="Escolha uma nova senha (mínimo 8 caracteres)."
      footer={
        <Link
          to="/entrar"
          className="font-medium text-primary underline-offset-4 hover:underline"
        >
          Voltar ao login
        </Link>
      }
    >
      <Card>
        <CardHeader>
          <CardTitle>Nova senha</CardTitle>
          <CardDescription>
            O token vem do link enviado por e-mail após &quot;Esqueci minha
            senha&quot;.
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
              <Label htmlFor={passwordId}>Nova senha</Label>
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
              <Label htmlFor={confirmId}>Confirmar nova senha</Label>
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
              {mutation.isPending ? "Salvando…" : "Salvar nova senha"}
            </Button>
          </form>
        </CardContent>
      </Card>
    </AuthPageShell>
  );
}
