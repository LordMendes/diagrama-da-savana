defmodule DiagramaSavana.Aportes.Simulacao do
  @moduledoc """
  Simulação de aporte em duas camadas (**macro** e **micro**) para a calculadora.

  - **Macro:** déficit em reais vs. meta com patrimônio pós-aporte — ver `DiagramaSavana.AporteMotor`.
  - **Micro:** nota de resistência e cotas inteiras com cotação brapi.
  """

  import Ecto.Query

  alias DiagramaSavana.Alvos
  alias DiagramaSavana.AporteMotor
  alias DiagramaSavana.Brapi.Client
  alias DiagramaSavana.Carteiras
  alias DiagramaSavana.Carteiras.Holding
  alias DiagramaSavana.Carteiras.Portfolio
  alias DiagramaSavana.Repo
  alias DiagramaSavana.Resistencia.Profile

  @doc """
  Executa a simulação para a carteira e o valor de aporte (string ou `Decimal`).
  """
  @spec run(Portfolio.t(), String.t() | Decimal.t()) ::
          {:ok, map()} | {:error, :invalid_amount | :negative_amount}
  def run(%Portfolio{} = portfolio, amount) when is_binary(amount) do
    case Decimal.parse(String.trim(amount)) do
      {d, _} -> run(portfolio, d)
      :error -> {:error, :invalid_amount}
    end
  end

  def run(%Portfolio{} = portfolio, %Decimal{} = amount) do
    cond do
      Decimal.compare(amount, Decimal.new(0)) != :gt ->
        {:error, :negative_amount}

      true ->
        {:ok, compute(portfolio, amount)}
    end
  end

  defp compute(%Portfolio{} = portfolio, %Decimal{} = aporte_amount) do
    holdings = Carteiras.list_holdings(portfolio)
    targets = Alvos.list_target_allocations(portfolio)
    target_by = Map.new(targets, fn t -> {t.macro_class, t.target_percent} end)

    quotes = fetch_quotes_map(holdings)
    quotes_partial = quotes_partial?(holdings, quotes)

    scores = load_scores(portfolio.user_id, holdings)

    {total_value, class_values} = class_values(holdings, quotes)
    total_after = Decimal.add(total_value, aporte_amount)

    {macro_layers, macro_unallocated} =
      AporteMotor.macro_value_shortfall(aporte_amount, total_after, class_values, target_by)

    {micro_allocations, micro_unallocated, warnings} =
      AporteMotor.micro_from_holdings(macro_layers, holdings, quotes, scores)

    unallocated =
      macro_unallocated
      |> Decimal.add(micro_unallocated)
      |> Decimal.round(2)

    %{
      amount: aporte_amount,
      portfolio_value_before: Decimal.round(total_value, 2),
      macro_layers: macro_layers,
      micro_allocations: micro_allocations,
      warnings: warnings,
      unallocated_amount: unallocated,
      quotes_partial: quotes_partial
    }
  end

  defp load_scores(user_id, holdings) when is_binary(user_id) do
    asset_ids =
      holdings
      |> Enum.map(& &1.asset_id)
      |> Enum.uniq()

    if asset_ids == [] do
      %{}
    else
      from(p in Profile,
        where: p.user_id == ^user_id and p.asset_id in ^asset_ids,
        select: {p.asset_id, p.computed_score}
      )
      |> Repo.all()
      |> Map.new()
    end
  end

  defp fetch_quotes_map(holdings) do
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

  defp class_values(holdings, quotes) do
    Enum.reduce(holdings, {Decimal.new("0"), %{}}, fn h, {tot, by_macro} ->
      macro = kind_to_macro(h.asset.kind)

      val =
        case position_value(h, quotes) do
          nil -> Decimal.new("0")
          v -> v
        end

      {Decimal.add(tot, val), Map.update(by_macro, macro, val, &Decimal.add(&1, val))}
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

  defp first_result(%{"results" => [%{} = row | _]}), do: {:ok, row}
  defp first_result(_), do: {:error, :empty}

  defp decimal_from_quote(row, key) do
    case Map.get(row, key) do
      nil -> {:error, :missing}
      v -> {:ok, to_decimal(v)}
    end
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

  defp kind_to_macro(:acao), do: :renda_variavel
  defp kind_to_macro(:etf), do: :renda_variavel
  defp kind_to_macro(:fii), do: :fiis
  defp kind_to_macro(:renda_fixa), do: :renda_fixa
  defp kind_to_macro(:internacional), do: :internacional
  defp kind_to_macro(:cripto), do: :cripto
  defp kind_to_macro(:outro), do: :outros
end
