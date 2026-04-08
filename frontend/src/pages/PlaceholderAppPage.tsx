import { Link } from "react-router-dom";

type Props = {
  title: string;
  description: string;
};

/** Rotas placeholder do shell (carteira, biblioteca, histórico). */
export function PlaceholderAppPage({ title, description }: Props) {
  return (
    <div className="flex flex-1 flex-col gap-4">
      <h1 className="text-2xl font-semibold text-foreground">{title}</h1>
      <p className="max-w-2xl text-muted-foreground">{description}</p>
      <p className="text-sm">
        <Link to="/app" className="text-primary underline-offset-4 hover:underline">
          Voltar ao painel
        </Link>
      </p>
    </div>
  );
}
