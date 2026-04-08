export function FieldMessages({ messages }: { messages: string[] | undefined }) {
  if (!messages?.length) {
    return null;
  }
  return (
    <ul className="mt-1.5 list-inside list-disc text-sm text-destructive" role="alert">
      {messages.map((m) => (
        <li key={m}>{m}</li>
      ))}
    </ul>
  );
}
