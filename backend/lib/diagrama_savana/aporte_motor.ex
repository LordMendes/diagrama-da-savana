defmodule DiagramaSavana.AporteMotor do
  @moduledoc """
  Núcleo puro da calculadora de **aporte e rebalanceamento** (macro + micro).

  **Macro:** com valor total da carteira **após** o aporte `T + A`, para cada classe com
  meta, calcula o déficit em reais `max(0, (T+A)×target% − valor_atual_classe)` e distribui
  o aporte `A` proporcionalmente a esses déficits. Classes sem meta ou sem déficit recebem 0.

  **Micro:** em cada classe, entre posições com nota **> 0** e cotação disponível, reparte o
  valor da classe pela nota e converte em **cotas inteiras** (`floor`).

  A orquestração com banco e brapi fica em `DiagramaSavana.Aportes.Simulacao`.
  """

  alias DiagramaSavana.Alvos.TargetAllocation

  @doc """
  Entrada:

  - `:amount` — valor do aporte (positivo).
  - `:total_value` — patrimônio atual **antes** do aporte.
  - `:value_by_macro` — valor por classe macro.
  - `:target_percent_by_macro` — meta % ou `nil` se ausente.
  - `:eligible_positions` — `macro => [%{holding_id, asset_id, ticker, score, price}]` com `price` > 0.

  Saída alinhada ao uso em API: `macro`, `recommendations`, `unallocated_amount`, `warnings`.
  """
  @spec compute(map()) :: {:ok, map()} | {:error, atom()}
  def compute(params) when is_map(params) do
    amount = params[:amount] || params["amount"]
    total_value = params[:total_value] || params["total_value"]
    value_by_macro = params[:value_by_macro] || params["value_by_macro"] || %{}
    target_by = params[:target_percent_by_macro] || params["target_percent_by_macro"] || %{}
    positions = params[:eligible_positions] || params["eligible_positions"] || %{}

    with {:ok, amount} <- positive_decimal(amount),
         {:ok, total_value} <- non_neg_decimal(total_value) do
      total_after = Decimal.add(total_value, amount)

      {macro_layers, macro_unallocated} =
        macro_value_shortfall(amount, total_after, value_by_macro, target_by)

      {recs, micro_unallocated, warns} =
        micro_from_positions(macro_layers, positions, TargetAllocation.macro_classes())

      unallocated = macro_unallocated |> Decimal.add(micro_unallocated) |> Decimal.round(2)

      {:ok,
       %{
         amount: amount,
         total_portfolio_value: total_value,
         macro: macro_layers,
         recommendations: recs,
         unallocated_amount: unallocated,
         warnings: warns
       }}
    end
  end

  defp positive_decimal(%Decimal{} = d) do
    case Decimal.compare(d, Decimal.new(0)) do
      :gt -> {:ok, d}
      _ -> {:error, :amount_invalid}
    end
  end

  defp positive_decimal(_), do: {:error, :amount_invalid}

  defp non_neg_decimal(%Decimal{} = d), do: {:ok, d}
  defp non_neg_decimal(_), do: {:error, :total_value_invalid}

  @doc false
  def macro_value_shortfall(aporte, total_after, class_values, target_by) do
    macro_order = TargetAllocation.macro_classes()

    shortfalls =
      Enum.map(macro_order, fn macro ->
        target_pct = Map.get(target_by, macro)
        cur_val = Map.get(class_values, macro, Decimal.new(0)) |> norm_dec()

        shortfall =
          if is_nil(target_pct) do
            Decimal.new(0)
          else
            desired =
              Decimal.mult(total_after, Decimal.div(target_pct, Decimal.new(100)))

            s = Decimal.sub(desired, cur_val)
            if Decimal.compare(s, Decimal.new(0)) == :gt, do: s, else: Decimal.new(0)
          end

        {macro, shortfall}
      end)

    sum_short =
      shortfalls
      |> Enum.map(&elem(&1, 1))
      |> Enum.reduce(Decimal.new(0), &Decimal.add/2)

    if Decimal.compare(sum_short, Decimal.new(0)) != :gt do
      layers =
        Enum.map(shortfalls, fn {macro, sf} ->
          %{
            macro_class: macro,
            amount: Decimal.new(0),
            shortfall_value: Decimal.round(sf, 2)
          }
        end)

      {layers, aporte}
    else
      layers =
        Enum.map(shortfalls, fn {macro, sf} ->
          amt = Decimal.div(Decimal.mult(aporte, sf), sum_short) |> Decimal.round(2, :half_up)

          %{
            macro_class: macro,
            amount: amt,
            shortfall_value: Decimal.round(sf, 2)
          }
        end)

      {layers, Decimal.new(0)}
    end
  end

  defp micro_from_positions(macro_layers, positions, macro_order) do
    by_amount = Map.new(macro_layers, &{&1.macro_class, &1.amount})

    Enum.reduce(macro_order, {[], Decimal.new(0), []}, fn macro, {accs, unacc, ws} ->
      amount = Map.get(by_amount, macro, Decimal.new(0))

      if Decimal.compare(amount, Decimal.new(0)) != :gt do
        {accs, unacc, ws}
      else
        list = Map.get(positions, macro, []) |> List.wrap()

        priced =
          Enum.filter(list, fn row ->
            score = row[:score] || row["score"]
            price = row[:price] || row["price"]

            is_integer(score) and score > 0 and match?(%Decimal{}, price) and
              Decimal.compare(price, Decimal.new(0)) == :gt
          end)
          |> Enum.sort_by(fn row ->
            {-(row[:score] || row["score"]), row[:holding_id] || row["holding_id"]}
          end)

        sum_w =
          priced
          |> Enum.map(&(&1[:score] || &1["score"]))
          |> Enum.sum()

        cond do
          priced == [] or sum_w <= 0 ->
            msg =
              "Nenhum ativo elegível (nota > 0 e cotação) em #{macro_label(macro)}; valor macro não alocado em cotas."

            {accs, Decimal.add(unacc, amount), [msg | ws]}

          true ->
            sum_w_dec = Decimal.new(sum_w)

            new_accs =
              Enum.map(priced, fn row ->
                score = row[:score] || row["score"]
                price = row[:price] || row["price"]
                hid = row[:holding_id] || row["holding_id"]
                aid = row[:asset_id] || row["asset_id"]
                ticker = row[:ticker] || row["ticker"] || ""
                score_d = Decimal.new(score)

                alloc =
                  Decimal.div(Decimal.mult(amount, score_d), sum_w_dec)
                  |> Decimal.round(2, :half_up)

                shares_dec = Decimal.div(alloc, price) |> Decimal.round(0, :floor)
                shares = Decimal.to_integer(shares_dec)
                spent = Decimal.mult(shares_dec, price) |> Decimal.round(2, :half_up)

                %{
                  holding_id: hid,
                  asset_id: aid,
                  ticker: ticker,
                  macro_class: macro,
                  resistance_score: score,
                  unit_price: price,
                  suggested_quantity: shares,
                  amount_brl: spent
                }
              end)

            allocated =
              Enum.reduce(new_accs, Decimal.new(0), fn r, a -> Decimal.add(a, r.amount_brl) end)

            leftover = Decimal.sub(amount, allocated) |> Decimal.round(2, :half_up)

            extra =
              if Decimal.compare(leftover, Decimal.new("0.01")) == :gt do
                [
                  "Sobra de #{Decimal.to_string(leftover)} em #{macro_label(macro)} após cotas inteiras."
                ]
              else
                []
              end

            {accs ++ new_accs, Decimal.add(unacc, leftover), extra ++ ws}
        end
      end
    end)
  end

  @doc """
  Usado por `Simulacao`: mesma lógica que `micro_from_positions`, com lista de `Holding` pré-carregada.
  """
  def micro_from_holdings(macro_layers, holdings, quotes, scores) when is_list(holdings) do
    by_macro_amount = Map.new(macro_layers, &{&1.macro_class, &1.amount})

    Enum.reduce(TargetAllocation.macro_classes(), {[], Decimal.new(0), []}, fn macro,
                                                                               {accs, unacc, ws} ->
      amount = Map.get(by_macro_amount, macro, Decimal.new(0))

      if Decimal.compare(amount, Decimal.new(0)) != :gt do
        {accs, unacc, ws}
      else
        in_class = Enum.filter(holdings, fn h -> kind_to_macro(h.asset.kind) == macro end)

        eligible =
          Enum.filter(in_class, fn h ->
            score = Map.get(scores, h.asset_id, 0)
            is_integer(score) and score > 0
          end)

        priced =
          Enum.filter(eligible, fn h ->
            price_from_quotes(quotes, h.asset.ticker) != nil
          end)

        sum_w =
          priced
          |> Enum.map(fn h -> Map.get(scores, h.asset_id, 0) end)
          |> Enum.sum()

        cond do
          eligible == [] ->
            msg =
              "Nenhum ativo elegível (nota > 0) em #{macro_label(macro)}; valor macro não alocado em cotas."

            {accs, Decimal.add(unacc, amount), [msg | ws]}

          priced == [] ->
            msg = "Cotações indisponíveis para ativos elegíveis em #{macro_label(macro)}."
            {accs, Decimal.add(unacc, amount), [msg | ws]}

          true ->
            sum_w_dec = Decimal.new(sum_w)

            new_accs =
              Enum.map(priced, fn h ->
                score = Map.get(scores, h.asset_id, 0)
                score_d = Decimal.new(score)
                price = price_from_quotes(quotes, h.asset.ticker)

                alloc =
                  Decimal.div(Decimal.mult(amount, score_d), sum_w_dec)
                  |> Decimal.round(2, :half_up)

                shares_dec = Decimal.div(alloc, price) |> Decimal.round(0, :floor)
                shares = Decimal.to_integer(shares_dec)
                spent = Decimal.mult(shares_dec, price) |> Decimal.round(2)

                %{
                  holding_id: h.id,
                  asset_id: h.asset_id,
                  ticker: h.asset.ticker,
                  macro_class: macro,
                  resistance_score: score,
                  unit_price: price,
                  shares: shares,
                  amount_brl: spent
                }
              end)

            allocated =
              Enum.reduce(new_accs, Decimal.new(0), fn r, a -> Decimal.add(a, r.amount_brl) end)

            leftover_rounded = Decimal.sub(amount, allocated) |> Decimal.round(2)

            extra_warn =
              if Decimal.compare(leftover_rounded, Decimal.new("0.01")) == :gt do
                [
                  "Sobra de #{Decimal.to_string(leftover_rounded)} em #{macro_label(macro)} após cotas inteiras."
                ]
              else
                []
              end

            {accs ++ new_accs, Decimal.add(unacc, leftover_rounded), extra_warn ++ ws}
        end
      end
    end)
  end

  defp price_from_quotes(quotes, ticker) do
    case Map.get(quotes, ticker) do
      {:ok, body} ->
        with {:ok, row} <- first_quote_row(body),
             {:ok, price} <- decimal_from_field(row, "regularMarketPrice") do
          price
        else
          _ -> nil
        end

      _ ->
        nil
    end
  end

  defp first_quote_row(%{"results" => [%{} = row | _]}), do: {:ok, row}
  defp first_quote_row(_), do: {:error, :empty}

  defp decimal_from_field(row, key) do
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
      :error -> Decimal.new(0)
    end
  end

  defp macro_label(:renda_fixa), do: "renda fixa"
  defp macro_label(:renda_variavel), do: "renda variável"
  defp macro_label(:fiis), do: "FIIs"
  defp macro_label(:internacional), do: "internacional"
  defp macro_label(:cripto), do: "cripto"
  defp macro_label(:outros), do: "outros"
  defp macro_label(other), do: to_string(other)

  defp kind_to_macro(:acao), do: :renda_variavel
  defp kind_to_macro(:etf), do: :renda_variavel
  defp kind_to_macro(:fii), do: :fiis
  defp kind_to_macro(:renda_fixa), do: :renda_fixa
  defp kind_to_macro(:internacional), do: :internacional
  defp kind_to_macro(:cripto), do: :cripto
  defp kind_to_macro(:outro), do: :outros

  defp norm_dec(%Decimal{} = d), do: d
  defp norm_dec(_), do: Decimal.new(0)
end
