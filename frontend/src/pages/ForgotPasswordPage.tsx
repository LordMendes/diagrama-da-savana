import { useMutation } from "@tanstack/react-query";
import { useId, useState } from "react";
import { Link } from "react-router-dom";
import { requestPasswordReset } from "@/api/auth";
import { AuthPageShell } from "@/components/auth/AuthPageShell";
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

export function ForgotPasswordPage() {
  const emailId = useId();
  const [email, setEmail] = useState("");

  const mutation = useMutation({
    mutationFn: () => requestPasswordReset(email.trim()),
  });

  const apiError = mutation.error instanceof ApiError ? mutation.error : null;

  if (mutation.isSuccess && mutation.data) {
    return (
      <AuthPageShell
        title="Verifique seu e-mail"
        description={mutation.data.data.message}
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
            <CardTitle>Solicitação enviada</CardTitle>
            <CardDescription>
              Se o endereço estiver cadastrado, você receberá um link para
              redefinir a senha. Confira também a caixa de spam.
            </CardDescription>
          </CardHeader>
          <CardContent>
            <p className="text-sm text-muted-foreground">
              Em desenvolvimento, mensagens podem aparecer no{" "}
              <a
                href="http://localhost:8025"
                target="_blank"
                rel="noreferrer"
                className="font-medium text-primary underline-offset-4 hover:underline"
              >
                MailHog
              </a>
              .
            </p>
          </CardContent>
        </Card>
      </AuthPageShell>
    );
  }

  return (
    <AuthPageShell
      title="Esqueci minha senha"
      description="Informe seu e-mail para receber o link de redefinição."
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
          <CardTitle>Recuperação</CardTitle>
          <CardDescription>
            Por segurança, a mensagem de confirmação é a mesma independentemente
            do e-mail existir ou não.
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
            {apiError ? (
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
              />
            </div>

            <Button
              type="submit"
              className="w-full"
              disabled={mutation.isPending}
            >
              {mutation.isPending ? "Enviando…" : "Enviar instruções"}
            </Button>
          </form>
        </CardContent>
      </Card>
    </AuthPageShell>
  );
}
