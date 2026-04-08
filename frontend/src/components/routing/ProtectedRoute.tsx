import { Navigate, Outlet, useLocation } from "react-router-dom";
import { useAuth } from "@/auth/auth-context";

export function ProtectedRoute() {
  const { isAuthenticated, isLoading } = useAuth();
  const location = useLocation();

  if (isLoading) {
    return (
      <div className="flex min-h-dvh items-center justify-center bg-gradient-to-b from-secondary/40 via-background to-muted/30">
        <div
          className="size-10 animate-spin rounded-full border-2 border-primary border-t-transparent"
          role="status"
          aria-label="Carregando sessão"
        />
      </div>
    );
  }

  if (!isAuthenticated) {
    return <Navigate to="/entrar" replace state={{ from: location }} />;
  }

  return <Outlet />;
}
