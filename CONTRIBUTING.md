# Contribuindo — Diagrama da Savana

## Regras do projeto

- Convenções da stack, pt-BR na UI, testes e segurança: `.cursor/rules/diagrama-da-savana.mdc` e [DOCS/Implementation/CONCEPT.md](DOCS/Implementation/CONCEPT.md).
- Fluxo de implementação por passos: [DOCS/Implementation/AGENT-WORKFLOW.md](DOCS/Implementation/AGENT-WORKFLOW.md).

## Executar testes

### Backend (Elixir / ExUnit)

Na raiz do repositório:

```bash
cd backend && mix test
```

Requer Elixir instalado e PostgreSQL para os testes que rodam `ecto.create` / `ecto.migrate` (veja [backend/README.md](backend/README.md) e Docker Compose na raiz). Use `DATABASE_PORT=5433` se subir o Postgres pelo `docker compose` deste repositório.

### Frontend (Vitest)

Na raiz do repositório:

```bash
cd frontend && pnpm install && pnpm test
```

Requer Node.js LTS e [pnpm](https://pnpm.io/installation) (por exemplo `corepack enable` e `corepack prepare pnpm@latest --activate`). O setup atual é scaffolding mínimo; o projeto Vite + React será expandido no step 2.2.

## Variáveis de ambiente e segredos

- Não commitar arquivos `.env` com segredos nem chaves de API.
- Documentar nomes de variáveis esperadas sem valores sensíveis.

## PostgreSQL local

- Desenvolvimento com banco em **Docker Compose**, conforme [DOCS/Implementation/AGENT-WORKFLOW.md](DOCS/Implementation/AGENT-WORKFLOW.md) e os passos de infraestrutura (ex.: step 2.1).
