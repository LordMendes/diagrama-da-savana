# Step 4.1 — UI de autenticação (login, cadastro, esqueci senha)

**Depende de:** `step 2.2.md` e `step 3.md` concluídos  
**Pode rodar em paralelo com:** `step 4.2.md`  
**Desbloqueia:** integração completa do fluxo de entrada do app

## Objetivo

Telas públicas de login, cadastro e recuperação de senha em pt-BR, consumindo a API do step 3, com tratamento de loading e erros amigável.

## Prompt para o agente (copiar e colar)

```
Implemente as telas de autenticação do "Diagrama da Savana" no frontend conforme DOCS/Implementation/CONCEPT.md.

Escopo — Step 4.1:
- Páginas: login, cadastro, esqueci minha senha, redefinir senha (link com token).
- Integração real com backend do step 3 (endpoints documentados no código ou README).
- TanStack Query para mutações; estados de loading e erro; mensagens em pt-BR.
- Formulários acessíveis e responsivos (shadcn/ui).

Não implemente o shell logado completo nem dashboard (step 4.2). Ao terminar, marque a checklist em DOCS/Implementation/step 4.1.md.
```

## Lista de tarefas (atualizar ao concluir)

- [x] Login e cadastro funcionando ponta a ponta
- [x] Fluxo esqueci/redefinir senha funcionando
- [x] Loading, erros e validação com UX clara em pt-BR
- [x] Testes de componente ou E2E smoke se previstos no step 1
- [x] Checklist deste arquivo atualizada
