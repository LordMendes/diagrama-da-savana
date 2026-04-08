defmodule DiagramaSavana.Carteiras.PortfolioSummary do
  @moduledoc false

  alias DiagramaSavana.Alvos
  alias DiagramaSavana.Aportes
  alias DiagramaSavana.Brapi.Client
  alias DiagramaSavana.Carteiras
  alias DiagramaSavana.Carteiras.{Holding, Portfolio}
  alias DiagramaSavana.Alvos.TargetAllocation

  @macro_order TargetAllocation.macro_classes()

  @doc """
  Agrega cotações (brapi), valores por classe macro e aportes recentes para o painel.
  """
  def build(%Portfolio{} = portfolio) do
    holdings = Carteiras.list_holdings(portfolio)
    targets = Alvos.list_target_allocations(portfolio)
    recent_aportes = Aportes.list_aportes(portfolio, limit: 10)

    quotes = fetch_quotes_for_holdings(holdings)
    quotes_partial = quotes_partial?(holdings, quotes)

    {total_value, daily_change_percent} = totals(holdings, quotes)
    allocation_rows = allocation_rows(holdings, quotes, targets, total_value)

    %{
      portfolio: portfolio,
      total_value: total_value,
      daily_change_percent: daily_change_percent,
      quotes_partial: quotes_partial,
      allocation_by_macro: allocation_rows,
      recent_aportes: recent_aportes
    }
  end

  defp fetch_quotes_for_holdings(holdings) do
    tickers =
      holdings
      |> Enum.map(fn %Holding{asset: a} -> a.ticker end)
      |> Enum.uniq()

    Enum.reduce(tickers, %{}, fn t, acc ->
      case Client.fetch_quote(t) do
        {:ok, body} -> Map.put(acc, t, {:ok, body})
        {:error, _} -> Map.put(acc, t, :error)
      end
    end)
  end

  defp quotes_partial?(holdings, quotes) do
    Enum.any?(holdings, fn %Holding{asset: a} ->
      Map.get(quotes, a.ticker) == :error
    end)
  end

  defp totals(holdings, quotes) do
    {sum_val, weighted_num, denom} =
      Enum.reduce(holdings, {Decimal.new("0"), Decimal.new("0"), Decimal.new("0")}, fn h,
                                                                                       {sv, wn,
                                                                                        wd} ->
        case position_value_and_change(h, quotes) do
          nil ->
            {sv, wn, wd}

          {val, ch_pct} ->
            ch = ch_pct || Decimal.new("0")
            wn2 = Decimal.add(wn, Decimal.mult(val, ch))
            wd2 = Decimal.add(wd, val)
            {Decimal.add(sv, val), wn2, wd2}
        end
      end)

    daily =
      if Decimal.compare(denom, Decimal.new("0")) == :gt do
        Decimal.div(weighted_num, denom) |> Decimal.round(4)
      else
        nil
      end

    {sum_val, daily}
  end

  defp position_value_and_change(%Holding{} = h, quotes) do
    case Map.get(quotes, h.asset.ticker) do
      :error ->
        nil

      {:ok, body} ->
        with {:ok, row} <- first_result(body),
             {:ok, price} <- decimal_from_quote(row, "regularMarketPrice") do
          val = Decimal.mult(h.quantity, price)
          ch = decimal_from_change(Map.get(row, "regularMarketChangePercent"))
          {val, ch}
        else
          _ -> nil
        end
    end
  end

  defp first_result(%{"results" => [%{} = row | _]}), do: {:ok, row}
  defp first_result(_), do: {:error, :empty}

  defp decimal_from_quote(row, key) do
    case Map.get(row, key) do
      nil -> {:error, :missing}
      v -> {:ok, to_decimal(v)}
    end
  end

  defp decimal_from_change(nil), do: nil

  defp decimal_from_change(v) do
    to_decimal(v)
  end

  defp to_decimal(%Decimal{} = d), do: d

  defp to_decimal(v) when is_integer(v), do: Decimal.new(v)

  defp to_decimal(v) when is_float(v), do: Decimal.from_float(v)

  defp to_decimal(v) when is_binary(v) do
    case Decimal.parse(String.trim(v)) do
      {d, _} -> d
      :error -> Decimal.new("0")
    end
  end

  defp allocation_rows(holdings, quotes, targets, total_value) do
    target_by = Map.new(targets, fn t -> {t.macro_class, t.target_percent} end)

    class_totals =
      Enum.reduce(holdings, %{}, fn h, acc ->
        macro = kind_to_macro(h.asset.kind)

        val =
          case position_value(h, quotes) do
            nil -> Decimal.new("0")
            v -> v
          end

        Map.update(acc, macro, val, &Decimal.add(&1, val))
      end)

    Enum.map(@macro_order, fn macro ->
      class_val = Map.get(class_totals, macro, Decimal.new("0"))

      current_pct =
        if Decimal.compare(total_value, Decimal.new("0")) == :gt do
          Decimal.div(class_val, total_value)
          |> Decimal.mult(Decimal.new(100))
          |> Decimal.round(2)
        else
          Decimal.new("0")
        end

      %{
        macro_class: macro,
        current_percent: current_pct,
        target_percent: Map.get(target_by, macro)
      }
    end)
  end

  defp position_value(%Holding{} = h, quotes) do
    case Map.get(quotes, h.asset.ticker) do
      :error ->
        nil

      {:ok, body} ->
        with {:ok, row} <- first_result(body),
             {:ok, price} <- decimal_from_quote(row, "regularMarketPrice") do
          Decimal.mult(h.quantity, price)
        else
          _ -> nil
        end
    end
  end

  defp kind_to_macro(:acao), do: :renda_variavel
  defp kind_to_macro(:etf), do: :renda_variavel
  defp kind_to_macro(:fii), do: :fiis
  defp kind_to_macro(:renda_fixa), do: :renda_fixa
  defp kind_to_macro(:internacional), do: :internacional
  defp kind_to_macro(:cripto), do: :cripto
  defp kind_to_macro(:outro), do: :outros
end
