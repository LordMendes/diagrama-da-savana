# Step 9 — Telas restantes: biblioteca de ativos, histórico, perfil

**Depende de:** `step 8.2.md` concluído  
**Pode rodar em paralelo com:** —  
**Desbloqueia:** `step 10.md`

## Objetivo

Biblioteca de ativos com busca, filtro ação/FII e nota de resistência; histórico de aportes e rebalanceamentos; perfil do usuário (editar dados, logout).

## Prompt para o agente (copiar e colar)

```
Complete as telas restantes do "Diagrama da Savana" conforme DOCS/Implementation/CONCEPT.md.

Escopo — Step 9:
- Biblioteca de ativos: autocomplete + filtro por tipo + exibição da nota de resistência.
- Histórico de aportes e rebalanceamentos (lista detalhada, filtros simples opcionais).
- Perfil: edição de dados básicos, logout; tudo em pt-BR.

Reutilize componentes e padrões dos passos anteriores. Ao terminar, marque a checklist em DOCS/Implementation/step 9.md.
```

## Lista de tarefas (atualizar ao concluir)

- [x] Biblioteca de ativos conforme especificação
- [x] Histórico persistido e exibido corretamente
- [x] Perfil e logout
- [x] Testes de regressão mínimos ou manuais documentados
- [x] Checklist deste arquivo atualizada

### Testes / verificação manual

- **Backend:** `cd backend && mix test test/diagrama_savana_web/controllers/api/v1/me_controller_test.exs` (requer PostgreSQL de teste configurado).
- **Frontend:** `cd frontend && pnpm test` (inclui `historico-aporte.test.ts`).
- **Manual:** `/app/biblioteca` (filtros + autocomplete brapi), `/app/historico` (filtro origem), `/app/perfil` (PATCH e-mail + sair).
