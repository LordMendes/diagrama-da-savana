import { Link, Outlet } from "react-router-dom";
import { useAuth } from "@/auth/auth-context";

export function PublicLayout() {
  const { isAuthenticated } = useAuth();

  return (
    <div className="flex min-h-dvh flex-col bg-gradient-to-b from-secondary/40 via-background to-muted/30">
      <header className="sticky top-0 z-10 border-b border-border/80 bg-background/80 backdrop-blur-md">
        <div className="mx-auto flex max-w-5xl flex-wrap items-center justify-between gap-3 px-4 py-3 sm:px-6">
          <Link
            to="/"
            className="text-lg font-semibold tracking-tight text-primary"
          >
            Diagrama da Savana
          </Link>
          <nav className="flex flex-wrap items-center gap-2 text-sm">
            <ButtonNav to="/">Início</ButtonNav>
            {isAuthenticated ? (
              <ButtonNav to="/app">Painel</ButtonNav>
            ) : (
              <>
                <ButtonNav to="/entrar">Entrar</ButtonNav>
                <ButtonNav to="/cadastro">Cadastro</ButtonNav>
              </>
            )}
          </nav>
        </div>
      </header>
      <main className="mx-auto flex w-full max-w-5xl flex-1 flex-col px-4 py-8 sm:px-6">
        <Outlet />
      </main>
      <footer className="border-t border-border/60 bg-muted/30 py-4 text-center text-xs text-muted-foreground">
        Diagrama da Savana — alocação e rebalanceamento de carteira
      </footer>
    </div>
  );
}

function ButtonNav({
  to,
  children,
}: {
  to: string;
  children: React.ReactNode;
}) {
  return (
    <Link
      to={to}
      className="rounded-md px-3 py-1.5 text-foreground/90 transition-colors hover:bg-accent/60 hover:text-accent-foreground"
    >
      {children}
    </Link>
  );
}
