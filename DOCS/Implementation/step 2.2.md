# Step 2.2 — Frontend: Vite, React, TypeScript, Tailwind, shadcn, TanStack Query

**Depende de:** `step 1.md` concluído  
**Pode rodar em paralelo com:** `step 2.1.md`  
**Desbloqueia:** `step 4.1.md`, `step 4.2.md` (junto com step 3)

## Objetivo

Criar o frontend com a stack obrigatória: React 18+, Vite, TypeScript, Tailwind CSS, shadcn/ui, React Router, TanStack Query; layout base responsivo e tema visual savana (verde, terra, laranja sutil) sem implementar telas de negócio completas.

## Prompt para o agente (copiar e colar)

```
Implemente o frontend base do "Diagrama da Savana" conforme DOCS/Implementation/CONCEPT.md.

Escopo — Step 2.2 apenas:
- Projeto Vite + React + TypeScript; Tailwind configurado; shadcn/ui instalado e um componente de exemplo.
- React Router com rotas placeholder (home pública, área logada vazia).
- TanStack Query com QueryClient no root.
- Tema de cores savana (CSS variables ou Tailwind theme); mobile-first.
- Scripts `pnpm dev`, `pnpm build`, `pnpm test` (Vitest + RTL se configurado no step 1).
- Textos visíveis ao usuário em pt-BR (labels dos placeholders inclusos).

Não integre ainda com API Phoenix real de auth (step 3/4); use placeholders. Ao terminar, marque a checklist em DOCS/Implementation/step 2.2.md.
```

## Lista de tarefas (atualizar ao concluir)

- [x] Vite + React + TS + Tailwind + shadcn/ui funcionando
- [x] React Router e TanStack Query configurados
- [x] Tema visual savana aplicado ao layout base
- [x] Rotas placeholder e UI pt-BR nos textos expostos
- [x] Testes frontend executáveis (mesmo que smoke)
- [x] Checklist deste arquivo atualizada
