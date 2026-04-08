# Step 4.2 — Shell da aplicação logada e rotas protegidas

**Depende de:** `step 2.2.md` e `step 3.md` concluídos (idealmente `step 4.1.md` para fluxo completo)  
**Pode rodar em paralelo com:** `step 4.1.md`  
**Desbloqueia:** dashboard e features autenticadas subsequentes

## Objetivo

Layout autenticado (header/nav, área principal), guard de rotas no React Router, redirecionamento login/dashboard, e dashboard placeholder alinhado ao CONCEPT.md.

## Prompt para o agente (copiar e colar)

```
Implemente o shell da área logada do "Diagrama da Savana" conforme DOCS/Implementation/CONCEPT.md.

Escopo — Step 4.2:
- Rotas protegidas: se não autenticado, redirecionar para login; após login, dashboard.
- Layout responsivo com navegação mínima (dashboard, carteira, etc. como links placeholder).
- Dashboard inicial: cards ou placeholders para valor total, gráfico, lista de aportes (dados mock ou vazio estruturado) — sem lógica de negócio real ainda se step 5 não estiver pronto.
- Persistência de sessão alinhada ao backend (token/cookie conforme step 3).

Coordene com step 4.1 para não duplicar providers de auth. Ao terminar, marque a checklist em DOCS/Implementation/step 4.2.md.
```

## Lista de tarefas (atualizar ao concluir)

- [x] Rotas privadas e redirecionamentos corretos
- [x] Layout logado responsivo e tema savana consistente
- [x] Dashboard placeholder com estrutura da visão descrita no CONCEPT
- [x] Integração com estado de autenticação compartilhado
- [x] Checklist deste arquivo atualizada
