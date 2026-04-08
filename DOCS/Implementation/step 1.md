# Step 1 — Fundação: qualidade de código, testes e orquestração de agentes

**Depende de:** nada (primeiro passo)  
**Pode rodar em paralelo com:** nenhum  
**Desbloqueia:** todos os demais passos

## Objetivo

Estabelecer regras persistentes para o projeto (qualidade, testes, convenções), definir o fluxo de trabalho para agentes executarem os passos na ordem correta (e quais passos são paralelos), e preparar o repositório para desenvolvimento seguro e repetível.

## Prompt para o agente (copiar e colar)

```
Você está no repositório do projeto "Diagrama da Savana" (web app full-stack descrita em DOCS/Implementation/CONCEPT.md).

Tarefa — Step 1 (fundação):

1) Regras de qualidade de código e testes
   - Crie ou atualize `.cursor/rules/` (ou `AGENTS.md` na raiz, se o time preferir um único arquivo) com regras claras para:
     - Stack: Elixir/Phoenix/Ecto/PostgreSQL no backend; React 18+ TypeScript, Vite, Tailwind, shadcn/ui, TanStack Query no frontend.
     - Idioma da UI e mensagens: pt-BR obrigatório.
     - Padrões: formatação (mix format, Prettier/ESLint conforme adotado), nomes de módulos e pastas, tratamento de erros e loading na UI.
     - Testes obrigatórios: ExUnit no Elixir para lógica de domínio, schemas e contextos críticos; Vitest/React Testing Library (ou equivalente já escolhido) para componentes e hooks críticos do frontend.
     - Integração: quando tocar em API brapi.dev, mencionar rate limiting, cache e variáveis de ambiente — sem commitar segredos.
     - Ambiente local: banco PostgreSQL via **Docker Compose** para desenvolvimento (alinhado a `AGENT-WORKFLOW.md` e ao step 2.1).
     - Arquivos **`.env.example`** por ambiente necessário: manter atualizados quando variáveis mudarem; comentário `#` acima de cada variável indicando **segredo** vs **público/não segredo**.
     - **`README.md`:** manter atualizado quando o fluxo de execução mudar; deve descrever pré-requisitos, env, Docker, comandos para subir backend e frontend e testes (ver regras do projeto).

2) Workflow para agentes (sequência e paralelismo)
   - Crie ou atualize `DOCS/Implementation/AGENT-WORKFLOW.md` (já pode existir no repositório) garantindo que descreve:
     - Ordem e paralelismo entre todos os `step *.md` presentes em `DOCS/Implementation/`.
     - Regra: só iniciar um passo quando os pré-requisitos listados naquele arquivo estiverem concluídos (checklists dos passos anteriores marcadas).
     - Como atualizar listas de tarefas: ao concluir um passo, marcar checkboxes no `.md` correspondente e commit coerente.

3) Infra mínima de teste (scaffolding)
   - Garantir que existam comandos documentados em README ou CONTRIBUTING para rodar testes backend e frontend (mesmo que ainda não haja testes — scripts placeholder ou `mix test` / `pnpm test` funcionando).

4) Ao terminar, marque todos os itens da checklist abaixo neste arquivo (`step 1.md`).

Não implemente features do produto além do necessário para regras, documentação de workflow e scaffolding de testes.
```

## Lista de tarefas (atualizar ao concluir)

- [x] Regras Cursor/AGENTS cobrindo stack, pt-BR, testes, segurança de env, atualização do README e passos para rodar o projeto
- [x] `DOCS/Implementation/AGENT-WORKFLOW.md` criado com ordem, paralelismo e regra de pré-requisitos
- [x] Comandos de teste documentados (backend e frontend)
- [x] Checklist deste arquivo revisada e marcada como concluída no último commit do passo
