# Step 2.1 — Backend: Phoenix, PostgreSQL, estrutura base

**Depende de:** `step 1.md` concluído  
**Pode rodar em paralelo com:** `step 2.2.md`  
**Desbloqueia:** `step 3.md`, `step 6.1.md`

## Objetivo

Criar a aplicação Phoenix (última versão estável), configurar PostgreSQL via Ecto com **PostgreSQL rodando em Docker Compose** para desenvolvimento local, variáveis de ambiente, estrutura de pastas clara, e base para rate limiting/cache (mesmo que stubs) alinhada ao CONCEPT.md.

## Prompt para o agente (copiar e colar)

```
Implemente o backend base do "Diagrama da Savana" conforme DOCS/Implementation/CONCEPT.md.

Escopo — Step 2.1 apenas:
- Novo app Phoenix + Ecto + PostgreSQL; configuração por variáveis de ambiente (DATABASE_URL, etc.).
- **Docker Compose** com serviço PostgreSQL para rodar o banco localmente (`docker compose up` ou equivalente); documentar porta, volume e como o Phoenix se conecta.
- Estrutura de contextos preparada para domínio (não precisa implementar regras de negócio completas ainda).
- Preparar hooks ou módulo para chamadas HTTP à brapi.dev com espaço para cache e rate limiting (implementação mínima ou TODO documentado).
- README ou seção com como rodar `mix test` e o servidor.
- Toda documentação de código/comentários orientativos podem ser em inglês ou pt-BR, mas a UI futura será pt-BR.

Não implemente autenticação completa (step 3) nem frontend (step 2.2). Ao terminar, marque a checklist em DOCS/Implementation/step 2.1.md.
```

## Lista de tarefas (atualizar ao concluir)

- [x] App Phoenix criado e sobe com `mix phx.server` (ou equivalente)
- [x] PostgreSQL no **docker-compose** para dev local; README com como subir o banco e conectar
- [x] PostgreSQL/Ecto configurados e migração inicial vazia ou mínima aplicável
- [x] Env documentados (sem commitar segredos)
- [x] Módulo ou boundary para cliente HTTP brapi + notas de rate limit/cache
- [x] `mix test` executa com sucesso
- [x] Checklist deste arquivo atualizada
