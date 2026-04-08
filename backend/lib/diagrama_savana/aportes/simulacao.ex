defmodule DiagramaSavana.Aportes.Simulacao do
  @moduledoc """
  Simulação de aporte em duas camadas (**macro** e **micro**) para a calculadora.

  - **Macro:** déficit em reais vs. meta com patrimônio pós-aporte — ver `DiagramaSavana.AporteMotor`.
  - **Micro:** nota de resistência e cotas inteiras com cotação brapi.
  """

  import Ecto.Query

  alias DiagramaSavana.Alvos
  alias DiagramaSavana.Alvos.TargetAllocation
  alias DiagramaSavana.AporteMotor
  alias DiagramaSavana.Aportes.SimulacaoCache
  alias DiagramaSavana.Brapi.Client
  alias DiagramaSavana.Carteiras
  alias DiagramaSavana.Carteiras.Holding
  alias DiagramaSavana.Carteiras.Portfolio
  alias DiagramaSavana.Repo
  alias DiagramaSavana.Resistencia.Profile

  @doc """
  Executa a simulação para a carteira e o valor de aporte (string ou `Decimal`).

  Opções:
  - `:cache` — se `true` (padrão), reutiliza resultado em cache (~30 min) quando a
    carteira, metas, notas de resistência e o valor normalizado não mudaram.
    Use `cache: false` ao aplicar aporte para sempre recalcular (ex.: `Carteiras.apply_aporte_simulation/3`).
  """
  @spec run(Portfolio.t(), String.t() | Decimal.t(), keyword()) ::
          {:ok, map()} | {:error, :invalid_amount | :negative_amount}
  def run(portfolio, amount, opts \\ [])

  def run(%Portfolio{} = portfolio, amount, opts) when is_binary(amount) do
    case Decimal.parse(String.trim(amount)) do
      {d, _} -> run(portfolio, d, opts)
      :error -> {:error, :invalid_amount}
    end
  end

  def run(%Portfolio{} = portfolio, %Decimal{} = amount, opts) when is_list(opts) do
    cond do
      Decimal.compare(amount, Decimal.new(0)) != :gt ->
        {:error, :negative_amount}

      Keyword.get(opts, :cache, true) ->
        run_cached(portfolio, amount)

      true ->
        {:ok, compute(portfolio, amount)}
    end
  end

  defp run_cached(%Portfolio{} = portfolio, %Decimal{} = amount) do
    version = simulation_inputs_version(portfolio.id, portfolio.user_id)
    key = simulacao_cache_key(portfolio, amount, version)

    case SimulacaoCache.get(key) do
      {:ok, cached} ->
        {:ok, cached}

      :miss ->
        result = compute(portfolio, amount)
        _ = SimulacaoCache.put(key, result, ttl: simulacao_cache_ttl_seconds())
        {:ok, result}
    end
  end

  defp simulacao_cache_key(%Portfolio{} = portfolio, %Decimal{} = amount, version) do
    {:simulacao_aporte, portfolio.user_id, portfolio.id, amount_cache_key(amount), version}
  end

  defp amount_cache_key(%Decimal{} = d) do
    d |> Decimal.normalize() |> Decimal.to_string(:normal)
  end

  defp simulacao_cache_ttl_seconds do
    Application.get_env(:diagrama_savana, :simulacao_aporte_cache, [])
    |> Keyword.get(:default_ttl_seconds, 1800)
  end

  defp simulation_inputs_version(portfolio_id, user_id) do
    holdings_max =
      Repo.one(
        from(h in Holding,
          where: h.portfolio_id == ^portfolio_id,
          select: max(h.updated_at)
        )
      )

    targets_max =
      Repo.one(
        from(t in TargetAllocation,
          where: t.portfolio_id == ^portfolio_id,
          select: max(t.updated_at)
        )
      )

    profiles_max =
      Repo.one(
        from(p in Profile,
          join: h in Holding,
          on: h.asset_id == p.asset_id,
          where: h.portfolio_id == ^portfolio_id and p.user_id == ^user_id,
          select: max(p.updated_at)
        )
      )

    {coalesce_utc(holdings_max), coalesce_utc(targets_max), coalesce_utc(profiles_max)}
  end

  defp coalesce_utc(nil), do: ~U[1970-01-01 00:00:00Z]

  defp coalesce_utc(%DateTime{} = dt), do: dt

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

    Client.fetch_quotes_many(tickers)
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
