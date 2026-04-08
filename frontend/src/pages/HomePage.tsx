import { Link } from "react-router-dom";
import { useAuth } from "@/auth/auth-context";
import { Button } from "@/components/ui/button";

export function HomePage() {
  const { isAuthenticated } = useAuth();

  return (
    <div className="flex flex-1 flex-col gap-8">
      <section className="space-y-4">
        <h1 className="text-3xl font-bold tracking-tight text-foreground sm:text-4xl">
          Diagrama da Savana
        </h1>
        <p className="max-w-2xl text-base text-muted-foreground sm:text-lg">
          Ferramenta de alocação e rebalanceamento de carteira. Esta é a página
          inicial pública — o conteúdo completo virá nos próximos passos.
        </p>
        <div className="flex flex-wrap gap-3">
          <Button asChild>
            <Link to={isAuthenticated ? "/app" : "/entrar"}>
              {isAuthenticated ? "Abrir o painel" : "Entrar"}
            </Link>
          </Button>
          {isAuthenticated ? (
            <Button variant="outline" type="button" asChild>
              <Link to="/app/carteira">Carteira</Link>
            </Button>
          ) : (
            <Button variant="outline" type="button" asChild>
              <Link to="/cadastro">Criar conta</Link>
            </Button>
          )}
        </div>
      </section>
    </div>
  );
}
