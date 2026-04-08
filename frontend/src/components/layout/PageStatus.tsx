import { Skeleton } from "@/components/ui/skeleton";

type PageLoadingProps = {
  title: string;
  description?: string;
  /** Layout variant for skeleton blocks */
  variant?: "dashboard" | "simple";
};

/**
 * Consistent loading state for authenticated pages (skeleton + visible title).
 */
export function PageLoading({
  title,
  description = "Carregando dados…",
  variant = "dashboard",
}: PageLoadingProps) {
  return (
    <div
      className="flex flex-1 flex-col gap-6"
      aria-busy="true"
      aria-live="polite"
    >
      <div>
        <h1 className="text-2xl font-semibold tracking-tight">{title}</h1>
        <p className="mt-1 text-sm text-muted-foreground">{description}</p>
      </div>
      {variant === "dashboard" ? (
        <>
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            <Skeleton className="h-28 rounded-xl" />
            <Skeleton className="h-28 rounded-xl sm:col-span-2" />
          </div>
          <Skeleton className="min-h-[12rem] rounded-xl" />
        </>
      ) : (
        <Skeleton className="min-h-[8rem] rounded-xl" />
      )}
    </div>
  );
}

type PageErrorProps = {
  title: string;
  message: string;
};

export function PageError({ title, message }: PageErrorProps) {
  return (
    <div className="flex flex-1 flex-col gap-4">
      <h1 className="text-2xl font-semibold tracking-tight">{title}</h1>
      <p className="text-sm text-destructive" role="alert">
        {message}
      </p>
    </div>
  );
}
