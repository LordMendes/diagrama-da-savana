# Step 8.1 — Motor de aporte e rebalanceamento (macro + micro)

**Depende de:** `step 5.md`, `step 6.1.md` e `step 7.md` concluídos  
**Pode rodar em paralelo com:** `step 8.2.md` apenas para UI com **contrato mockado** acordado — produção exige este passo antes  
**Desbloqueia:** `step 8.2.md` (integração final)

## Objetivo

Implementar algoritmo em duas camadas: macro (gap vs metas de classe, priorizar defasados), micro (distribuição por Nota de Resistência entre aprovados; usar cotação brapi para quantidade de cotas); expor API clara e testes unitários pesados.

## Prompt para o agente (copiar e colar)

```
Implemente o motor de cálculo de aporte e rebalanceamento do "Diagrama da Savana" conforme DOCS/Implementation/CONCEPT.md.

Escopo — Step 8.1:
- Entrada: valor do aporte (ex.: R$ 5.000); estado da carteira, metas, holdings, scores, cotações.
- Camada macro: distribuir entre classes sub-alvo; ignorar classes no ou acima do target conforme especificação.
- Camada micro: entre ativos com nota > 0, ponderar pela nota; calcular cotas inteiras com preço atual.
- Saída estruturada (JSON) com recomendações por ativo e valores.
- ExUnit cobrindo casos extremos (carteira vazia, uma classe, empate, nota zero).

Opcional neste passo: endpoint `POST` de simulação. Ao terminar, marque a checklist em DOCS/Implementation/step 8.1.md.
```

## Lista de tarefas (atualizar ao concluir)

- [x] Lógica macro implementada e testada (`DiagramaSavana.AporteMotor.macro_value_shortfall/4`, `compute/1`)
- [x] Lógica micro implementada e testada (`micro_from_positions` / `micro_from_holdings`)
- [x] Integração com cotações e scores (`DiagramaSavana.Aportes.Simulacao`, brapi `Client.fetch_quote`)
- [x] API/contrato JSON documentado para o frontend (`DomainJSON` + `SimulacaoAporteController`, `README` backend)
- [x] Checklist deste arquivo atualizada
