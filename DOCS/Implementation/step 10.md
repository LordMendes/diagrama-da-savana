# Step 10 — Polimento, Docker Compose e documentação de execução

**Depende de:** `step 9.md` concluído  
**Pode rodar em paralelo com:** —  
**Desbloqueia:** release / deploy

## Objetivo

Revisar loading/erros em todo o app, responsividade, `docker-compose` unificado (ou serviços alinhados) com **PostgreSQL** (step 2.1) e **MailHog** para email local (step 3), mais Phoenix + frontend conforme CONCEPT, README com instruções completas de desenvolvimento e produção, checklist de env.

## Prompt para o agente (copiar e colar)

```
Finalize o polimento e a entrega local do "Diagrama da Savana" conforme DOCS/Implementation/CONCEPT.md.

Escopo — Step 10:
- Revisão de UX: loading, erros amigáveis, mobile.
- docker-compose: serviços Phoenix, PostgreSQL, **MailHog** (continuidade do que foi definido nos steps 2.1 e 3), build do frontend (ou monorepo documentado); arquivos `.env.example` por ambiente com comentários segredo vs público (regra do projeto).
- README raiz: pré-requisitos, comandos para subir stack, rodar migrações, testes, seed opcional.
- Garantir que requisitos técnicos adicionais do CONCEPT (rate limit, cache, i18n pt-BR) estão verificados ou documentados como limitações.

Ao terminar, marque a checklist em DOCS/Implementation/step 10.md.
```

## Lista de tarefas (atualizar ao concluir)

- [x] UX de loading/erro revisada nas telas principais
- [x] `docker-compose` funcionando para dev (PostgreSQL + MailHog + stack acordada; alinhado aos steps 2.1 e 3)
- [x] README completo e `.env.example` (ou equivalentes por pasta) atualizados
- [x] Passada final de testes backend + frontend
- [x] Checklist deste arquivo atualizada
