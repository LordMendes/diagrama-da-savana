# Step 8.2 — UI da calculadora e “Aplicar no portfólio”

**Depende de:** `step 8.1.md` concluído (mínimo: contrato da API de simulação)  
**Pode rodar em paralelo com:** desenvolvimento de `step 8.1` só com mocks — **conclusão** após 8.1  
**Desbloqueia:** `step 9.md`

## Objetivo

Tela para informar valor do aporte, exibir resultado acionável (“Com R$ X, aloque … compre N cotas de …”), loading/erros, botão aplicar que atualiza quantidades no portfólio (opcional mas recomendado).

## Prompt para o agente (copiar e colar)

```
Implemente a interface da calculadora de aporte do "Diagrama da Savana" conforme DOCS/Implementation/CONCEPT.md.

Escopo — Step 8.2:
- Formulário de valor de aporte; chamada à API do step 8.1; exibição clara da recomendação macro/micro.
- Botão "Aplicar no portfólio" que persiste novas quantidades (transação segura no backend).
- Estados de loading, erro e sucesso em pt-BR; responsivo.

Ao terminar, marque a checklist em DOCS/Implementation/step 8.2.md.
```

## Lista de tarefas (atualizar ao concluir)

- [x] UX completa da calculadora alinhada ao CONCEPT
- [x] Integração com API real do step 8.1
- [x] Aplicar no portfólio funcionando e testado
- [x] Testes de UI ou E2E principais
- [x] Checklist deste arquivo atualizada
