import { Link } from "react-router-dom";

export function AuthPageShell({
  title,
  description,
  children,
  footer,
}: {
  title: string;
  description?: string;
  children: React.ReactNode;
  footer?: React.ReactNode;
}) {
  return (
    <div className="mx-auto flex w-full max-w-md flex-col gap-6">
      <div className="space-y-2 text-center sm:text-left">
        <h1 className="text-2xl font-semibold tracking-tight text-foreground">
          {title}
        </h1>
        {description ? (
          <p className="text-sm text-muted-foreground">{description}</p>
        ) : null}
      </div>
      {children}
      {footer ? (
        <p className="text-center text-sm text-muted-foreground">{footer}</p>
      ) : null}
      <p className="text-center text-sm">
        <Link to="/" className="text-primary underline-offset-4 hover:underline">
          Voltar ao início
        </Link>
      </p>
    </div>
  );
}
