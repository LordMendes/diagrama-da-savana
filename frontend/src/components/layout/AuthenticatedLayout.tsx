import { Link, NavLink, Outlet } from "react-router-dom";
import { useAuth } from "@/auth/auth-context";
import { Button } from "@/components/ui/button";

const navClass = ({ isActive }: { isActive: boolean }) =>
  [
    "rounded-md px-3 py-2 text-sm font-medium transition-colors",
    isActive
      ? "bg-primary/15 text-primary"
      : "text-muted-foreground hover:bg-muted hover:text-foreground",
  ].join(" ");

export function AuthenticatedLayout() {
  const { user, signOut } = useAuth();

  return (
    <div className="flex min-h-dvh flex-col bg-gradient-to-b from-secondary/30 via-background to-muted/20">
      <header className="sticky top-0 z-10 border-b border-border/80 bg-card/90 pt-[env(safe-area-inset-top)] backdrop-blur-md">
        <div className="mx-auto flex max-w-6xl flex-col gap-4 px-4 py-4 sm:flex-row sm:items-center sm:justify-between sm:px-6">
          <div className="flex flex-wrap items-center justify-between gap-3">
            <Link
              to="/app"
              className="text-lg font-semibold tracking-tight text-primary"
            >
              Diagrama da Savana
            </Link>
            <p className="max-w-[min(100%,20rem)] truncate text-xs text-muted-foreground sm:hidden">
              {user?.email}
            </p>
          </div>
          <nav
            className="flex flex-wrap items-center gap-1 border-t border-border/60 pt-3 sm:border-t-0 sm:pt-0"
            aria-label="Principal"
          >
            <NavLink to="/app" end className={navClass}>
              Painel
            </NavLink>
            <NavLink to="/app/carteira" className={navClass}>
              Carteira
            </NavLink>
            <NavLink to="/app/calculadora" className={navClass}>
              Calculadora
            </NavLink>
            <NavLink to="/app/nota-resistencia" className={navClass}>
              Nota de resistência
            </NavLink>
            <NavLink to="/app/biblioteca" className={navClass}>
              Biblioteca
            </NavLink>
            <NavLink to="/app/historico" className={navClass}>
              Histórico
            </NavLink>
            <NavLink to="/app/perfil" className={navClass}>
              Perfil
            </NavLink>
          </nav>
          <div className="flex flex-wrap items-center gap-2 sm:justify-end">
            <span className="hidden max-w-[14rem] truncate text-xs text-muted-foreground sm:inline">
              {user?.email}
            </span>
            <Button variant="outline" size="sm" type="button" asChild>
              <Link to="/">Site</Link>
            </Button>
            <Button
              variant="secondary"
              size="sm"
              type="button"
              onClick={() => void signOut()}
            >
              Sair
            </Button>
          </div>
        </div>
      </header>
      <main className="mx-auto flex w-full max-w-6xl flex-1 flex-col px-4 py-8 pb-[max(2rem,env(safe-area-inset-bottom))] sm:px-6">
        <Outlet />
      </main>
    </div>
  );
}
