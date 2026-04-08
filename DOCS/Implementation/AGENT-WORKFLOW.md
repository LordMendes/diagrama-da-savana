# Workflow de agentes — Diagrama da Savana

Este documento define **em que ordem** os passos de implementação devem ser executados e **quais passos podem rodar em paralelo**.

## Regras

1. **Pré-requisitos:** Só iniciar o trabalho descrito em um `step *.md` quando todos os itens da checklist dos passos dos quais ele depende estiverem marcados como concluídos (checkboxes `[x]` no Markdown).
2. **Atualização de estado:** Ao terminar um passo, o agente deve marcar **todos** os checkboxes da seção "Lista de tarefas" daquele `step *.md` como concluídos (`- [x]`) e registrar no repositório com um **commit** cuja mensagem identifique o passo concluído (ex.: `docs: conclui step 2.1`).
3. **Paralelismo:** Passos com o mesmo número principal e sufixo `.1`, `.2`, … são **independentes entre si** desde que os pré-requisitos listados em **cada** arquivo estejam satisfeitos.

### Inventário de arquivos de passo

Todos os passos vivem em `DOCS/Implementation/`:

`step 1.md`, `step 2.1.md`, `step 2.2.md`, `step 3.md`, `step 4.1.md`, `step 4.2.md`, `step 5.md`, `step 6.1.md`, `step 6.2.md`, `step 7.md`, `step 8.1.md`, `step 8.2.md`, `step 9.md`, `step 10.md`.

A ordem, paralelismo e dependências detalhadas estão nas tabelas e no grafo abaixo.

## Banco de dados local

O **PostgreSQL para desenvolvimento local** deve ser executado via **Docker Compose** (serviço `postgres` ou equivalente), com `DATABASE_URL` (ou variáveis alinhadas ao Phoenix) documentadas para apontar para esse container. O passo **2.1** introduz o `docker-compose` mínimo com o banco; o passo **10** pode estendê-lo com Phoenix, frontend e demais serviços conforme o CONCEPT.

## Email em desenvolvimento local (MailHog)

Para **testar envio de email localmente** (cadastro, esqueci minha senha, etc.), o passo **3** deve usar **[MailHog](https://github.com/mailhog/MailHog)** (ou equivalente documentado, ex. Mailpit com a mesma função) via **Docker Compose**: serviço SMTP que captura mensagens e UI web (tipicamente porta **8025**) para inspeção. O backend (Swoosh/Bamboo) deve apontar para esse SMTP em **dev**; testes podem usar o adapter de teste do framework ou o mesmo compose conforme documentado. O passo **10** pode incluir MailHog no `docker-compose` unificado, em continuidade ao definido no step 3.

## Arquivos de passo (referência)

| Arquivo | Conteúdo resumido |
|---------|---------------------|
| `step 1.md` | Regras de qualidade, testes, workflow; scaffolding de testes |
| `step 2.1.md` | Phoenix, PostgreSQL, base backend |
| `step 2.2.md` | Vite, React, Tailwind, shadcn, Query, tema |
| `step 3.md` | Autenticação backend + email |
| `step 4.1.md` | UI login/cadastro/recuperação |
| `step 4.2.md` | Shell logado, rotas protegidas, dashboard placeholder |
| `step 5.md` | Domínio Ecto: carteira, metas, holdings |
| `step 6.1.md` | brapi.dev, cache, rate limiting |
| `step 6.2.md` | Gestão de carteira API + UI + dashboard com dados |
| `step 7.md` | Nota de Resistência |
| `step 8.1.md` | Motor macro/micro de aportes |
| `step 8.2.md` | UI calculadora + aplicar no portfólio |
| `step 9.md` | Biblioteca, histórico, perfil |
| `step 10.md` | Polimento, Docker Compose, README |

## Grafo de dependências

```
step 1
 ├── step 2.1 ──┬── step 3 ──┬── step 4.1
 │              │            ├── step 4.2
 │              ├── step 5 ──┼── step 6.2 ── step 7 ── step 8.1 ── step 8.2 ── step 9 ── step 10
 │              │            │
 └── step 2.2 ──┘            └── (4.x precisam de 2.2 + 3)

step 6.1 depende de step 2.1; alimenta 6.2, 8.1 e telas com cotação.
```

### Ordem linear sugerida (quando não há paralelismo)

`step 1` → `step 2.1` + `step 2.2` (paralelo) → `step 3` → `step 4.1` + `step 4.2` (paralelo) → `step 5` → `step 6.1` → `step 6.2` → `step 7` → `step 8.1` → `step 8.2` → `step 9` → `step 10`

### Paralelos seguros (após pré-requisitos)

| Paralelo | Pré-requisitos comuns |
|----------|------------------------|
| `step 2.1` ∥ `step 2.2` | `step 1` |
| `step 4.1` ∥ `step 4.2` | `step 2.2`, `step 3` |
| `step 8.2` (só UI com mocks) ∥ `step 8.1` | acordar contrato JSON; integração final após `step 8.1` |

### Dependências explícitas

- **2.1, 2.2** → após **1**
- **3** → após **2.1**
- **4.1, 4.2** → após **2.2** e **3**
- **5** → após **3**
- **6.1** → após **2.1**
- **6.2** → após **5** e **6.1** (e área logada de **4.2** para UI)
- **7** → após **5** e **6.2**
- **8.1** → após **5**, **6.1**, **7**
- **8.2** → após **8.1** (lógica/API); UI pode ser esboçada antes com mock
- **9** → após **8.2**
- **10** → após **9**
