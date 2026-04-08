defmodule DiagramaSavana.Carteiras do
  @moduledoc """
  Carteiras (portfólios) e posições (**holdings**) por usuário.
  """

  import Ecto.Query

  alias DiagramaSavana.Accounts.User
  alias DiagramaSavana.Aportes
  alias DiagramaSavana.Aportes.Simulacao
  alias DiagramaSavana.Carteiras.{Holding, Portfolio, PortfolioSummary}
  alias DiagramaSavana.Repo

  @default_portfolio_name "Principal"

  def list_portfolios(%User{id: user_id}) do
    from(p in Portfolio, where: p.user_id == ^user_id, order_by: [asc: p.name])
    |> Repo.all()
  end

  def get_portfolio(%User{id: user_id}, id) do
    case Repo.get(Portfolio, id) do
      %Portfolio{user_id: ^user_id} = p -> {:ok, p}
      %Portfolio{} -> {:error, :not_found}
      nil -> {:error, :not_found}
    end
  end

  def get_portfolio!(%User{} = user, id) do
    case get_portfolio(user, id) do
      {:ok, p} -> p
      {:error, :not_found} -> raise Ecto.NoResultsError, queryable: Portfolio
    end
  end

  def create_portfolio(%User{id: user_id}, attrs) when is_map(attrs) do
    %Portfolio{}
    |> Portfolio.create_changeset(Map.put(attrs, :user_id, user_id))
    |> Repo.insert()
  end

  def update_portfolio(%Portfolio{} = portfolio, attrs) do
    portfolio
    |> Portfolio.update_changeset(attrs)
    |> Repo.update()
  end

  def delete_portfolio(%Portfolio{name: @default_portfolio_name}), do: {:error, :default_readonly}

  def delete_portfolio(%Portfolio{} = portfolio) do
    Repo.delete(portfolio)
  end

  @doc """
  Garante uma carteira padrão `"#{@default_portfolio_name}"` para o usuário.
  """
  def ensure_default_portfolio(%User{id: user_id} = user) do
    case Repo.get_by(Portfolio, user_id: user_id, name: @default_portfolio_name) do
      %Portfolio{} = p -> {:ok, p}
      nil -> create_portfolio(user, %{name: @default_portfolio_name})
    end
  end

  def list_holdings(%Portfolio{id: portfolio_id}) do
    from(h in Holding,
      where: h.portfolio_id == ^portfolio_id,
      preload: [:asset],
      order_by: [asc: h.inserted_at]
    )
    |> Repo.all()
  end

  def get_holding(%User{} = user, portfolio_id, holding_id) do
    with {:ok, %Portfolio{id: ^portfolio_id} = portfolio} <- get_portfolio(user, portfolio_id),
         %Holding{} = h <- Repo.get(Holding, holding_id),
         true <- h.portfolio_id == portfolio.id do
      {:ok, Repo.preload(h, :asset)}
    else
      {:error, _} -> {:error, :not_found}
      nil -> {:error, :not_found}
      false -> {:error, :not_found}
    end
  end

  def create_holding(%Portfolio{} = portfolio, attrs) when is_map(attrs) do
    %Holding{}
    |> Holding.changeset(Map.put(attrs, :portfolio_id, portfolio.id))
    |> Repo.insert()
  end

  def update_holding(%Holding{} = holding, attrs) do
    holding
    |> Holding.changeset(attrs)
    |> Repo.update()
  end

  def delete_holding(%Holding{} = holding), do: Repo.delete(holding)

  @doc """
  Resumo agregado para o painel (cotações brapi, % por classe macro, aportes recentes).
  """
  def portfolio_summary(%Portfolio{} = portfolio), do: PortfolioSummary.build(portfolio)

  @doc """
  Simula aporte e rebalanceamento (macro + micro). Ver `DiagramaSavana.Aportes.Simulacao`.
  """
  def simulate_aporte(%Portfolio{} = portfolio, amount), do: Simulacao.run(portfolio, amount)

  @doc """
  Reexecuta a simulação e aplica compras de cotas (transação) + registro de aporte.

  Usa apenas o valor informado como fonte de verdade; o cliente não envia cotas calculadas.
  """
  def apply_aporte_simulation(%User{} = user, portfolio_id, amount_input) do
    with {:ok, %Portfolio{} = portfolio} <- get_portfolio(user, portfolio_id) do
      Repo.transaction(fn ->
        case Simulacao.run(portfolio, amount_input, cache: false) do
          {:error, reason} ->
            Repo.rollback(reason)

          {:ok, sim} ->
            case apply_micro_allocations(user, portfolio, sim.micro_allocations) do
              :ok ->
                case Aportes.create_aporte(portfolio, %{
                       amount: sim.amount,
                       note: "Calculadora de aporte",
                       occurred_on: Date.utc_today()
                     }) do
                  {:ok, aporte} -> %{simulation: sim, aporte: aporte}
                  {:error, cs} -> Repo.rollback({:aporte, cs})
                end

              {:error, reason} ->
                Repo.rollback(reason)
            end
        end
      end)
    end
  end

  defp apply_micro_allocations(user, portfolio, rows) do
    Enum.reduce_while(rows, :ok, fn row, :ok ->
      if row.shares <= 0 do
        {:cont, :ok}
      else
        case get_holding(user, portfolio.id, row.holding_id) do
          {:ok, h} ->
            case apply_holding_buy(h, row) do
              :ok -> {:cont, :ok}
              {:error, cs} -> {:halt, {:error, {:holding, cs}}}
            end

          {:error, :not_found} ->
            {:halt, {:error, :holding_not_found}}
        end
      end
    end)
  end

  defp apply_holding_buy(%Holding{} = h, row) do
    price = row.unit_price
    add_q = Decimal.new(row.shares)
    new_qty = Decimal.add(h.quantity, add_q)

    new_avg =
      Decimal.div(
        Decimal.add(Decimal.mult(h.quantity, h.average_price), Decimal.mult(add_q, price)),
        new_qty
      )
      |> Decimal.round(8)

    case update_holding(h, %{quantity: new_qty, average_price: new_avg}) do
      {:ok, _} -> :ok
      {:error, cs} -> {:error, cs}
    end
  end
end
