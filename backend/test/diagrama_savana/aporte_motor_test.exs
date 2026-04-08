defmodule DiagramaSavana.AporteMotorTest do
  use ExUnit.Case, async: true

  alias DiagramaSavana.AporteMotor
  alias DiagramaSavana.Alvos.TargetAllocation

  describe "compute/1 — macro + micro" do
    test "carteira vazia com meta só em RV: todo o aporte vai para RV e vira cotas" do
      p10 = Decimal.new("10")

      positions = %{
        renda_variavel: [
          %{
            holding_id: "00000000-0000-0000-0000-000000000001",
            asset_id: "00000000-0000-0000-0000-0000000000a1",
            ticker: "AAA",
            score: 4,
            price: p10
          }
        ]
      }

      assert {:ok, r} =
               AporteMotor.compute(%{
                 amount: Decimal.new("5000"),
                 total_value: Decimal.new(0),
                 value_by_macro: %{},
                 target_percent_by_macro: %{renda_variavel: Decimal.new(100)},
                 eligible_positions: positions
               })

      rv = Enum.find(r.macro, &(&1.macro_class == :renda_variavel))
      assert Decimal.compare(rv.amount, Decimal.new("5000")) == :eq

      [rec] = r.recommendations
      assert rec.suggested_quantity == 500
      assert rec.ticker == "AAA"
    end

    test "uma classe macro com dois ativos em empate de nota divide o valor e respeita cotas inteiras" do
      p100 = Decimal.new("100")

      positions = %{
        renda_variavel: [
          %{
            holding_id: "00000000-0000-0000-0000-000000000001",
            asset_id: "a1",
            ticker: "AAA",
            score: 3,
            price: p100
          },
          %{
            holding_id: "00000000-0000-0000-0000-000000000002",
            asset_id: "a2",
            ticker: "BBB",
            score: 3,
            price: p100
          }
        ]
      }

      assert {:ok, r} =
               AporteMotor.compute(%{
                 amount: Decimal.new("200"),
                 total_value: Decimal.new(0),
                 value_by_macro: %{},
                 target_percent_by_macro: %{renda_variavel: Decimal.new(100)},
                 eligible_positions: positions
               })

      qties =
        r.recommendations
        |> Enum.filter(&(&1.macro_class == :renda_variavel))
        |> Enum.map(& &1.suggested_quantity)

      assert Enum.sort(qties) == [1, 1]
    end

    test "nota zero ou ausente: ativo não recebe recomendação; valor fica como sobra micro" do
      positions = %{
        renda_variavel: [
          %{
            holding_id: "h1",
            asset_id: "a1",
            ticker: "BAD",
            score: 0,
            price: Decimal.new("10")
          },
          %{
            holding_id: "h2",
            asset_id: "a2",
            ticker: "GOOD",
            score: 2,
            price: Decimal.new("10")
          }
        ]
      }

      # Valor com centavos que geram sobra após cotas inteiras (único ativo com nota > 0 absorve o macro).
      assert {:ok, r} =
               AporteMotor.compute(%{
                 amount: Decimal.new("101"),
                 total_value: Decimal.new(0),
                 value_by_macro: %{},
                 target_percent_by_macro: %{renda_variavel: Decimal.new(100)},
                 eligible_positions: positions
               })

      assert [_] = r.recommendations
      assert hd(r.recommendations).ticker == "GOOD"
      refute Enum.any?(r.recommendations, &(&1.ticker == "BAD"))
      assert Decimal.compare(r.unallocated_amount, Decimal.new(0)) == :gt
    end

    test "sem metas macro: soma de déficits zero e o aporte inteiro fica não alocado" do
      positions = %{
        renda_variavel: [
          %{
            holding_id: "h1",
            asset_id: "a1",
            ticker: "X",
            score: 5,
            price: Decimal.new("10")
          }
        ]
      }

      assert {:ok, r} =
               AporteMotor.compute(%{
                 amount: Decimal.new("1000"),
                 total_value: Decimal.new("10000"),
                 value_by_macro: %{renda_variavel: Decimal.new("10000")},
                 target_percent_by_macro: %{},
                 eligible_positions: positions
               })

      assert r.recommendations == []
      assert Decimal.compare(r.unallocated_amount, Decimal.new("1000")) == :eq
    end

    test "valor de aporte inválido" do
      assert {:error, :amount_invalid} =
               AporteMotor.compute(%{
                 amount: Decimal.new("-1"),
                 total_value: Decimal.new(0),
                 value_by_macro: %{},
                 target_percent_by_macro: %{},
                 eligible_positions: %{}
               })
    end
  end

  describe "macro_value_shortfall/4" do
    test "duas classes defasadas: proporcional ao déficit em reais" do
      total_after = Decimal.new("11000")
      class_values = %{renda_variavel: Decimal.new("0"), fiis: Decimal.new("0")}
      target_by = %{renda_variavel: Decimal.new(50), fiis: Decimal.new(50)}

      {layers, unalloc} =
        AporteMotor.macro_value_shortfall(
          Decimal.new("1000"),
          total_after,
          class_values,
          target_by
        )

      assert Decimal.compare(unalloc, Decimal.new(0)) == :eq

      by = Map.new(layers, &{&1.macro_class, &1.amount})
      # desired RV 5500, FIIs 5500; shortfalls 5500 each → 50/50 do aporte
      assert Decimal.compare(by[:renda_variavel], Decimal.new("500")) == :eq
      assert Decimal.compare(by[:fiis], Decimal.new("500")) == :eq
    end
  end

  test "ordem das classes macro é estável (TargetAllocation.macro_classes/0)" do
    ms = TargetAllocation.macro_classes()
    assert ms == [:renda_fixa, :renda_variavel, :fiis, :internacional, :cripto, :outros]
  end
end
