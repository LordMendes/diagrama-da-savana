# Step 6.1 — Integração brapi.dev: busca, cotação, cache e rate limiting

**Depende de:** `step 2.1.md` concluído (idealmente também `step 5.md` para associar dados)  
**Pode rodar em paralelo com:** trabalho em `step 5.md` se a API brapi for isolada em boundary  
**Desbloqueia:** autocomplete e preços em `step 6.2`, `step 7`, `step 8.1`

## Objetivo

Cliente servidor para brapi.dev com busca de tickers, cotação atual e histórico simples; cache (ETS/Cachex ou similar) e rate limiting; endpoints JSON para o frontend; variável `BRAPI_TOKEN` ou equivalente.

## Prompt para o agente (copiar e colar)

```
Integre a API brapi.dev no backend Phoenix do "Diagrama da Savana" conforme DOCS/Implementation/CONCEPT.md.

Escopo — Step 6.1:
- Módulo de cliente HTTP com timeouts e tratamento de erro.
- Endpoints: busca/autocomplete de tickers (ações, FIIs, ETFs BR), quote atual, histórico quando necessário.
- Rate limiting e cache básico documentados (respeitar limites do plano gratuito).
- Testes com mocks HTTP (Mox ou Bypass) — sem chamar API real em CI.
- Documentar env vars no README.

Não implemente UI de autocomplete (step 6.2). Ao terminar, marque a checklist em DOCS/Implementation/step 6.1.md.
```

## Lista de tarefas (atualizar ao concluir)

- [x] Cliente brapi com configuração por env
- [x] Endpoints JSON expostos e documentados para o frontend
- [x] Cache e rate limiting funcionando ou claramente instrumentados
- [x] Testes com mocks, CI estável
- [x] Checklist deste arquivo atualizada
