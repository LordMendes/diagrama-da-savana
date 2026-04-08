# Step 6.2 — Gestão de carteira: API + UI (ativos, metas, aportes recentes)

**Depende de:** `step 5.md` e `step 6.1.md` concluídos; `step 4.2.md` para área logada  
**Pode rodar em paralelo com:** —  
**Desbloqueia:** dados reais no dashboard; `step 7.md`

## Objetivo

Permitir editar % alvo por classe macro, adicionar ativos com busca/autocomplete (debounce) usando brapi, armazenar quantidade e preço médio; listar aportes recentes (estrutura mínima); integrar visão resumida no dashboard.

## Prompt para o agente (copiar e colar)

```
Implemente a gestão de carteira do "Diagrama da Savana" conforme DOCS/Implementation/CONCEPT.md.

Escopo — Step 6.2:
- Backend: CRUD/alternativas REST para metas por classe, holdings, ligação com cotações via step 6.1.
- Frontend: telas fluxo de edição de metas; busca de ticker com debounce e UI shadcn; tabela ou cards de posições; lista de aportes recentes (pode ser log de transações simples).
- Dashboard: valor total e % por classe com dados reais quando possível; variação diária via brapi.
- Tudo em pt-BR na UI.

Não implemente Nota de Resistência completa (step 7) nem calculadora de aporte (step 8). Ao terminar, marque a checklist em DOCS/Implementation/step 6.2.md.
```

## Lista de tarefas (atualizar ao concluir)

- [x] Metas macro editáveis e persistidas
- [x] Adição de ativos com autocomplete + brapi
- [x] Holdings com quantidade e preço médio
- [x] Dashboard alimentado com dados reais (onde aplicável)
- [x] Testes backend + testes críticos frontend
- [x] Checklist deste arquivo atualizada
