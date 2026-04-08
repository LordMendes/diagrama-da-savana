import { Route, Routes } from "react-router-dom";
import { AuthenticatedLayout } from "@/components/layout/AuthenticatedLayout";
import { PublicLayout } from "@/components/layout/PublicLayout";
import { ProtectedRoute } from "@/components/routing/ProtectedRoute";
import { DashboardPage } from "@/pages/DashboardPage";
import { ForgotPasswordPage } from "@/pages/ForgotPasswordPage";
import { HomePage } from "@/pages/HomePage";
import { LoginPage } from "@/pages/LoginPage";
import { BibliotecaAtivosPage } from "@/pages/BibliotecaAtivosPage";
import { CalculadoraAportePage } from "@/pages/CalculadoraAportePage";
import { CarteiraPage } from "@/pages/CarteiraPage";
import { HistoricoPage } from "@/pages/HistoricoPage";
import { NotaResistenciaPage } from "@/pages/NotaResistenciaPage";
import { MovimentacaoPrecoMedioPage } from "@/pages/MovimentacaoPrecoMedioPage";
import { PerfilPage } from "@/pages/PerfilPage";
import { RegisterPage } from "@/pages/RegisterPage";
import { ResetPasswordPage } from "@/pages/ResetPasswordPage";

export default function App() {
  return (
    <Routes>
      <Route element={<PublicLayout />}>
        <Route index element={<HomePage />} />
        <Route path="entrar" element={<LoginPage />} />
        <Route path="cadastro" element={<RegisterPage />} />
        <Route path="esqueci-senha" element={<ForgotPasswordPage />} />
        <Route path="redefinir-senha" element={<ResetPasswordPage />} />
      </Route>

      <Route element={<ProtectedRoute />}>
        <Route path="app" element={<AuthenticatedLayout />}>
          <Route index element={<DashboardPage />} />
          <Route path="carteira" element={<CarteiraPage />} />
          <Route
            path="calculadora"
            element={<CalculadoraAportePage />}
          />
          <Route
            path="nota-resistencia"
            element={<NotaResistenciaPage />}
          />
          <Route path="biblioteca" element={<BibliotecaAtivosPage />} />
          <Route path="historico" element={<HistoricoPage />} />
          <Route
            path="movimentacao-preco-medio"
            element={<MovimentacaoPrecoMedioPage />}
          />
          <Route path="perfil" element={<PerfilPage />} />
        </Route>
      </Route>
    </Routes>
  );
}
