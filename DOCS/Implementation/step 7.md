# Step 7 — Nota de Resistência (scoring -5 a +10)

**Depende de:** `step 5.md` e `step 6.2.md` concluídos  
**Pode rodar em paralelo com:** —  
**Desbloqueia:** `step 8.1.md`

## Objetivo

Checklist por tipo (ações vs FIIs), critérios +1/-1, persistência do score por holding/ativo, regra de exclusão: nota ≤ 0 não entra em alocação; UI formulário clara em pt-BR.

## Prompt para o agente (copiar e colar)

```
Implemente a Nota de Resistência do "Diagrama da Savana" conforme DOCS/Implementation/CONCEPT.md.

Escopo — Step 7:
- Modelo `ResistanceScore` (ou equivalente) ligado ao ativo/holding; critérios separados para ações e FIIs.
- UI: formulário com toggles ou botões +1/-1 por critério; exibir resultado final (-5 a +10).
- Regra de negócio: ativos com nota ≤ 0 excluídos de cálculos de alocação (preparar hook para step 8).
- Testes ExUnit para cálculo do score e limites.

Não implemente a calculadora de aporte (step 8). Ao terminar, marque a checklist em DOCS/Implementation/step 7.md.
```

## Lista de tarefas (atualizar ao concluir)

- [x] Persistência e validação dos critérios e score
- [x] UI completa em pt-BR por tipo de ativo
- [x] Regra de exclusão (≤ 0) aplicável na camada de domínio
- [x] Testes de domínio e API
- [x] Checklist deste arquivo atualizada
