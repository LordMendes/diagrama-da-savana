# Diagrama da Savana — backend (Phoenix)

API e camada de domínio em **Elixir / Phoenix / Ecto / PostgreSQL**.

## Pré-requisitos

- Elixir e Erlang/OTP (veja `mix.exs` para a versão mínima de Elixir).
- PostgreSQL acessível em desenvolvimento (recomendado: Docker Compose na raiz do repositório).

## Banco de dados (Docker Compose)

Na raiz do repositório (não dentro de `backend/`):

```bash
docker compose up -d postgres mailhog
```

O serviço expõe o Postgres na porta **5433** do host (para evitar conflito com um Postgres local na 5432). Ajuste o app com:

```bash
export DATABASE_PORT=5433
```

Ou use `DATABASE_URL` (veja `.env.example`). Credenciais padrão do compose: usuário `postgres`, senha `postgres`, banco `diagrama_savana_dev`.

### MailHog (e-mail em desenvolvimento)

O serviço `mailhog` no Compose expõe SMTP em **localhost:1025** e uma interface web em [http://localhost:8025](http://localhost:8025). Em `dev`, o backend envia e-mails (ex.: redefinição de senha) para esse SMTP. Fluxo rápido:

1. Suba o Compose com `mailhog` (comando acima).
2. Chame `POST /api/v1/password-reset` com um e-mail cadastrado.
3. Abra a UI do MailHog e confira a mensagem e o link com `token`.

Variáveis opcionais: `SMTP_HOST`, `SMTP_PORT` (padrão `localhost` / `1025`).

Primeira configuração do schema:

```bash
cd backend
mix deps.get
mix ecto.create
mix ecto.migrate
```

Atalho: `mix setup` (dependências + `ecto.setup`).

## Variáveis de ambiente

Copie `.env.example` para `.env` e preencha o que for necessário. Não commite segredos. Nomes usados pelo app incluem:

- `DATABASE_URL` (opcional; sobrescreve host/porta/usuário/senha em dev/test quando definida)
- `DATABASE_HOST`, `DATABASE_PORT`, `DATABASE_USER`, `DATABASE_PASSWORD`, `DATABASE_NAME`
- `BRAPI_BASE_URL`, `BRAPI_API_TOKEN` (ou `BRAPI_TOKEN`), `BRAPI_RATE_LIMIT_PER_MINUTE`, `BRAPI_CACHE_TTL_SECONDS`
- Autenticação: `GUARDIAN_SECRET_KEY` (obrigatório em produção), `PUBLIC_APP_URL` (links de redefinição de senha), `SMTP_HOST`, `SMTP_PORT`, `MAILER_FROM_EMAIL`, `MAILER_FROM_NAME`

## Autenticação (API JSON)

O frontend (Vite) é separado do Phoenix; a API usa **JWT** via [**Guardian**](https://hexdocs.pm/guardian) e hash de senha com **Bcrypt** (Comeonin). **Pow** não foi usado aqui porque as versões publicadas no Hex ainda restringem Phoenix a versões anteriores à 1.8, incompatível com este projeto.

| Método | Rota | Autenticação |
|--------|------|----------------|
| `POST` | `/api/v1/registration` | Não |
| `POST` | `/api/v1/session` | Não |
| `POST` | `/api/v1/password-reset` | Não |
| `PUT` | `/api/v1/password-reset` | Não (corpo com `token`, `password`, `password_confirmation`) |
| `POST` | `/api/v1/session/renew` | Header `Authorization: Bearer` + token de renovação (JWT) |
| `DELETE` | `/api/v1/session` | Header `Authorization: Bearer` + access token (JWT) |
| `GET` | `/api/v1/me` | Header `Authorization: Bearer` + access token (JWT) |

### Domínio (carteira, ativos, metas, nota de resistência)

Todas exigem `Authorization: Bearer` + access token. Envelope de sucesso: `{ "data": ... }`; erros de validação: `{ "errors": { "campo": ["mensagem"] } }`. Formato JSON dos recursos documentado em `DiagramaSavanaWeb.API.V1.DomainJSON`.

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/api/v1/portfolios` | Lista carteiras do usuário |
| `POST` | `/api/v1/portfolios` | Cria carteira (`portfolio.name`) |
| `GET` | `/api/v1/portfolios/:id` | Detalhe |
| `PATCH`/`PUT` | `/api/v1/portfolios/:id` | Atualiza nome |
| `DELETE` | `/api/v1/portfolios/:id` | Remove (a carteira `"Principal"` não pode ser excluída) |
| `GET` | `/api/v1/assets` | Lista ativos (catálogo global) |
| `POST` | `/api/v1/assets` | Cadastra ativo (`asset.ticker`, `asset.kind`) |
| `GET` | `/api/v1/assets/:id` | Detalhe do ativo |
| `GET` | `/api/v1/portfolios/:portfolio_id/holdings` | Posições |
| `POST` | `/api/v1/portfolios/:portfolio_id/holdings` | Cria posição (`holding.asset_id` ou `holding.ticker` + `holding.kind`; `quantity`, `average_price`) |
| `GET` | `/api/v1/portfolios/:portfolio_id/holdings/:id` | Detalhe da posição |
| `PATCH` | `/api/v1/portfolios/:portfolio_id/holdings/:id` | Atualiza quantidade/preço médio |
| `DELETE` | `/api/v1/portfolios/:portfolio_id/holdings/:id` | Remove posição |
| `GET` | `/api/v1/portfolios/:portfolio_id/target_allocations` | Metas % por classe macro |
| `POST` | `/api/v1/portfolios/:portfolio_id/target_allocations` | Cria meta (`macro_class`, `target_percent`) |
| `GET` | `/api/v1/portfolios/:portfolio_id/target_allocations/:id` | Detalhe |
| `PATCH` | `/api/v1/portfolios/:portfolio_id/target_allocations/:id` | Atualiza |
| `DELETE` | `/api/v1/portfolios/:portfolio_id/target_allocations/:id` | Remove |
| `POST` | `/api/v1/portfolios/:portfolio_id/simulacao_aporte` | Simula aporte/rebalanceamento (`simulacao_aporte.amount`) — ver `DomainJSON.simulacao_result/1` |
| `POST` | `/api/v1/portfolios/:portfolio_id/simulacao_aporte/aplicar` | Aplica compras calculadas + registro de aporte |
| `GET` | `/api/v1/resistance_criteria` | Query `kind=acao` (ações/ETFs), `kind=fii` ou `kind=cripto` — lista critérios do checklist |
| `GET` | `/api/v1/resistance_profiles` | Lista perfis de nota de resistência |
| `GET` | `/api/v1/resistance_profiles/:asset_id` | Perfil por ativo |
| `PUT` | `/api/v1/resistance_profiles/:asset_id` | Cria/atualiza com `resistance_profile.criteria` (mapa id → −1, 0 ou 1); `computed_score` é calculado no servidor (−5 a +10) |
| `DELETE` | `/api/v1/resistance_profiles/:asset_id` | Remove |

### Mercado (brapi.dev)

Proxy autenticado: o frontend não chama a brapi diretamente; o backend aplica **rate limiting** (ETS, `BRAPI_RATE_LIMIT_PER_MINUTE`) e **cache** (`BRAPI_CACHE_TTL_SECONDS`) nos módulos `DiagramaSavana.Brapi.*`. Por padrão as cotações são **uma requisição por ticker**; cotação em lote (`BRAPI_QUOTE_BATCH_SIZE` + `BRAPI_QUOTE_BATCH_ENABLED=true`) só para planos brapi que permitam `/quote/A,B,...`.

A simulação de aporte (`POST .../simulacao_aporte`) usa cache em memória do resultado por carteira/valor/versão dos dados (`SIMULACAO_APORTE_CACHE_TTL_SECONDS`, padrão **1800** s). A aplicação (`.../simulacao_aporte/aplicar`) **não** usa esse cache.

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/api/v1/market/search?q=` | Busca de tickers (ações, FIIs, ETFs) para autocomplete |
| `GET` | `/api/v1/market/quotes/:ticker` | Cotação; query opcional `range`, `interval` (histórico, conforme documentação brapi) |

Respostas de erro seguem o formato `{ "error": { "code", "message", ... } }` com textos em **pt-BR** para o cliente.

## Executar o servidor

```bash
cd backend
mix phx.server
```

Abre em [http://localhost:4000](http://localhost:4000) (página inicial gerada pelo Phoenix).

## Testes

Com PostgreSQL disponível (mesmo host/porta que `config/test.exs`; use `DATABASE_PORT=5433` se usar o compose):

```bash
cd backend
mix test
```

## Integração brapi.dev

Módulos em `lib/diagrama_savana/brapi/`:

- `Client` — orquestra cache e rate limiting; HTTP via `ReqTransport` (em testes: `TransportMock` + Mox, sem chamadas reais).
- `ReqTransport` — `Req` com timeout de leitura 15s e tratamento de 429/erros.
- `RateLimiter` — limite por minuto (ETS), escopos `:quote` e `:available`; em produção pode evoluir para store distribuído.
- `Cache` — cache em memória (ETS) com TTL; substituível por Redis/Cachex conforme necessidade.

Documentação Phoenix: [https://hexdocs.pm/phoenix/overview.html](https://hexdocs.pm/phoenix/overview.html)
