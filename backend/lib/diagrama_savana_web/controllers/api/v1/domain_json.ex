defmodule DiagramaSavanaWeb.API.V1.DomainJSON do
  @moduledoc """
  Formatação JSON do domínio (carteiras, ativos, metas, nota de resistência).

  Contrato consumido pelo frontend: envelopes `data` / `errors` alinhados ao restante da API v1.

  **Simulação de aporte** (`simulacao_result/1`): `amount`, `portfolio_value_before`, `macro_layers`
  (`macro_class`, `amount`, `shortfall_value`), `micro_allocations` (`holding_id`, `asset_id`, `ticker`,
  `macro_class`, `resistance_score`, `unit_price`, `shares`, `amount_brl`), `unallocated_amount`,
  `warnings`, `quotes_partial`.
  """

  alias DiagramaSavana.Alvos.TargetAllocation
  alias DiagramaSavana.Aportes.Aporte
  alias DiagramaSavana.Ativos.Asset
  alias DiagramaSavana.Carteiras.{Holding, Portfolio}
  alias DiagramaSavana.Resistencia.Profile

  def portfolio(%Portfolio{} = p) do
    %{
      id: p.id,
      name: p.name,
      inserted_at: p.inserted_at,
      updated_at: p.updated_at
    }
  end

  def asset(%Asset{} = a) do
    %{
      id: a.id,
      ticker: a.ticker,
      kind: a.kind |> to_kind_string(),
      inserted_at: a.inserted_at,
      updated_at: a.updated_at
    }
  end

  def holding(%Holding{} = h) do
    asset =
      if Ecto.assoc_loaded?(h.asset) do
        case h.asset do
          %Asset{} = a -> asset(a)
          _ -> nil
        end
      else
        nil
      end

    %{
      id: h.id,
      quantity: decimal_string(h.quantity),
      average_price: decimal_string(h.average_price),
      asset: asset,
      inserted_at: h.inserted_at,
      updated_at: h.updated_at
    }
  end

  def target_allocation(%TargetAllocation{} = t) do
    %{
      id: t.id,
      macro_class: to_macro_string(t.macro_class),
      target_percent: decimal_string(t.target_percent),
      inserted_at: t.inserted_at,
      updated_at: t.updated_at
    }
  end

  def aporte(%Aporte{} = a) do
    %{
      id: a.id,
      amount: decimal_string(a.amount),
      note: a.note,
      occurred_on: Date.to_iso8601(a.occurred_on),
      inserted_at: a.inserted_at,
      updated_at: a.updated_at
    }
  end

  def portfolio_summary(%{portfolio: %Portfolio{} = p} = summary) do
    %{
      portfolio: portfolio(p),
      total_value: decimal_string(summary.total_value),
      daily_change_percent: decimal_string(summary.daily_change_percent),
      quotes_partial: summary.quotes_partial,
      allocation_by_macro: Enum.map(summary.allocation_by_macro, &allocation_macro_row/1),
      recent_aportes: Enum.map(summary.recent_aportes, &aporte/1)
    }
  end

  defp allocation_macro_row(%{
         macro_class: macro,
         current_percent: cur,
         target_percent: tgt
       }) do
    %{
      macro_class: to_macro_string(macro),
      current_percent: decimal_string(cur),
      target_percent: if(is_nil(tgt), do: nil, else: decimal_string(tgt))
    }
  end

  def simulacao_result(%{
        amount: amount,
        portfolio_value_before: portfolio_value_before,
        macro_layers: macro_layers,
        micro_allocations: micro_allocations,
        warnings: warnings,
        unallocated_amount: unallocated_amount,
        quotes_partial: quotes_partial
      }) do
    %{
      amount: decimal_string(amount),
      portfolio_value_before: decimal_string(portfolio_value_before),
      macro_layers: Enum.map(macro_layers, &simulacao_macro_row/1),
      micro_allocations: Enum.map(micro_allocations, &simulacao_micro_row/1),
      warnings: warnings,
      unallocated_amount: decimal_string(unallocated_amount),
      quotes_partial: quotes_partial
    }
  end

  defp simulacao_macro_row(%{
         macro_class: macro,
         amount: amt,
         shortfall_value: sf
       }) do
    %{
      macro_class: to_macro_string(macro),
      amount: decimal_string(amt),
      shortfall_value: decimal_string(sf)
    }
  end

  defp simulacao_micro_row(%{
         holding_id: hid,
         asset_id: aid,
         ticker: t,
         macro_class: macro,
         resistance_score: sc,
         unit_price: p,
         shares: sh,
         amount_brl: ab
       }) do
    %{
      holding_id: hid,
      asset_id: aid,
      ticker: t,
      macro_class: to_macro_string(macro),
      resistance_score: sc,
      unit_price: decimal_string(p),
      shares: sh,
      amount_brl: decimal_string(ab)
    }
  end

  def resistance_profile(%Profile{} = p) do
    asset =
      if Ecto.assoc_loaded?(p.asset) do
        case p.asset do
          %Asset{} = a -> asset(a)
          _ -> nil
        end
      else
        nil
      end

    score = p.computed_score

    %{
      id: p.id,
      asset_id: p.asset_id,
      computed_score: score,
      criteria: p.criteria_stub || %{},
      eligible_for_allocation: is_integer(score) and score > 0,
      asset: asset,
      inserted_at: p.inserted_at,
      updated_at: p.updated_at
    }
  end

  defp decimal_string(nil), do: nil
  defp decimal_string(%Decimal{} = d), do: Decimal.to_string(d)

  defp to_kind_string(kind) when is_atom(kind), do: Atom.to_string(kind)
  defp to_kind_string(kind), do: to_string(kind)

  defp to_macro_string(m) when is_atom(m), do: Atom.to_string(m)
  defp to_macro_string(m), do: to_string(m)
end
