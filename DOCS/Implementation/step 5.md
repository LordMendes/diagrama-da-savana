# Step 5 — Domínio: carteira, metas, holdings e schemas Ecto

**Depende de:** `step 3.md` concluído  
**Pode rodar em paralelo com:** nada crítico (após 3)  
**Desbloqueia:** `step 6.2.md`, `step 7.md`

## Objetivo

Schemas e migrações: User (se ainda não coberto), Portfolio, classes macro, TargetAllocation, Asset/Holding, vínculos com usuário; contextos Ecto com operações CRUD básicas e testes.

## Prompt para o agente (copiar e colar)

```
Modele o domínio de dados do "Diagrama da Savana" conforme DOCS/Implementation/CONCEPT.md.

Escopo — Step 5:
- Migrações Ecto: portfolio por usuário, alocações alvo por classe macro, holdings com quantidade e preço médio, ativos referenciando ticker e tipo (ação/FII/ETF etc.).
- Schemas e contextos (`Portfolio`, `Holding`, …) com validações.
- ExUnit para changesets e operações críticas.
- API JSON (ou contrato claro) para o frontend consumir depois — sem UI neste passo.

Inclua campo/estrutura para Nota de Resistência será expandido no step 7. Ao terminar, marque a checklist em DOCS/Implementation/step 5.md.
```

## Lista de tarefas (atualizar ao concluir)

- [x] Migrações aplicadas e reversíveis conforme boas práticas
- [x] Schemas Portfolio, alocações, holdings e ativos coerentes com o CONCEPT
- [x] Contextos com CRUD e testes ExUnit
- [x] Endpoints ou contrato documentado para o frontend
- [x] Checklist deste arquivo atualizada
