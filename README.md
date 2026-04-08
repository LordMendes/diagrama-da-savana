# Diagrama da Savana

Aplicação web full-stack descrita em [DOCS/Implementation/CONCEPT.md](DOCS/Implementation/CONCEPT.md).

## Pré-requisitos

- **Elixir** e **Erlang/OTP** (versão mínima em `backend/mix.exs`).
- **Node.js** (LTS) e **pnpm** (gerenciador do frontend; ex.: `corepack enable` e `corepack prepare pnpm@latest --activate`).
- **Docker** (Docker Compose v2) para PostgreSQL e MailHog em desenvolvimento.

## Configuração

1. Copie os exemplos de variáveis (não commite `.env` com segredos):
   - `backend/.env.example` → `backend/.env`
   - `frontend/.env.example` → `frontend/.env` (opcional; necessário se mudar a URL da API)
2. Cada arquivo `.env.example` usa comentários `#` indicando **segredo** (não versionar valor real) vs **público** (URLs/portas de exemplo).
3. No backend, em **dev** e **test**, o `config/runtime.exs` carrega `backend/.env` no ambiente do processo (para `mix ecto.*` e o servidor enxergarem `DATABASE_URL` e demais variáveis). Variáveis já exportadas no shell continuam tendo prioridade.

## Subir dependências locais (Docker Compose)

Na raiz do repositório:

```bash
docker compose up -d postgres mailhog
```

| Serviço    | Uso |
|------------|-----|
| PostgreSQL | Porta **5433** no host → `DATABASE_PORT=5433` ou `DATABASE_URL` (ver `backend/.env.example`). |
| MailHog    | SMTP **1025**; interface de e-mails [http://localhost:8025](http://localhost:8025). |

Phoenix e o Vite **não** rodam dentro deste Compose (desenvolvimento com hot reload no host). O Compose entrega banco e captura de e-mail alinhados aos steps 2.1 e 3.

## Backend (Phoenix)

```bash
cd backend
mix deps.get
mix ecto.create
mix ecto.migrate
mix phx.server
```

Atalho após clonar: `mix setup` (dependências + `ecto.setup`). API padrão: [http://localhost:4000](http://localhost:4000).

## Frontend (Vite + React)

```bash
cd frontend
pnpm install
pnpm dev
```

Interface padrão: [http://localhost:5173](http://localhost:5173). Em dev, o Vite encaminha `/api/*` para o Phoenix em `localhost:4000` (veja `frontend/vite.config.ts`). Área autenticada: `/app`.

## Migrações e seed opcional

| Ação | Comando (a partir de `backend/`) |
|------|----------------------------------|
| Migrações | `mix ecto.migrate` |
| Seed | `mix run priv/repo/seeds.exs` (arquivo base vazio; personalize se precisar de dados iniciais) |
| Setup completo do banco | `mix ecto.setup` (create + migrate + seed) |

## Testes

| Área | Comando (na raiz do repositório) |
|------|----------------------------------|
| Backend | `cd backend && mix test` |
| Frontend | `cd frontend && pnpm install && pnpm test` |

Use `DATABASE_PORT=5433` nos testes se o Postgres vier do Compose.

## Produção (visão geral)

- Build do frontend: `cd frontend && pnpm build` (saída em `frontend/dist/`).
- Release Elixir: `MIX_ENV=prod mix release` em `backend/`; exige `DATABASE_URL`, `SECRET_KEY_BASE`, `PHX_HOST`, `PORT` e demais variáveis em `backend/.env.example` / `config/runtime.exs`.
- Configure SMTP real em produção (não MailHog); segredos apenas via ambiente ou secrets do provedor.

## Requisitos do CONCEPT (referência)

| Tema | Situação |
|------|----------|
| **pt-BR na interface** | Textos da UI e mensagens de erro voltadas ao usuário em português brasileiro. |
| **Rate limiting / cache (brapi.dev)** | Implementados no backend (`DiagramaSavana.Brapi.RateLimiter`, `DiagramaSavana.Brapi.Cache`); tune `BRAPI_RATE_LIMIT_PER_MINUTE` e `BRAPI_CACHE_TTL_SECONDS`. Detalhes em [backend/README.md](backend/README.md). |
| **Responsivo** | Layout mobile-first (Tailwind); área logada com navegação adaptável. |

## Documentação adicional

- **Ordem dos passos de implementação:** [DOCS/Implementation/AGENT-WORKFLOW.md](DOCS/Implementation/AGENT-WORKFLOW.md)
- **Contribuição e testes:** [CONTRIBUTING.md](CONTRIBUTING.md)
- **API e env do backend:** [backend/README.md](backend/README.md)
- **Rotas da área logada:** painel `/app`, carteira `/app/carteira`, calculadora `/app/calculadora`, nota de resistência `/app/nota-resistencia`, biblioteca `/app/biblioteca`, histórico `/app/historico`, perfil `/app/perfil`. Autenticação: `/entrar`, `/cadastro`, `/esqueci-senha`, `/redefinir-senha` (token na query).
