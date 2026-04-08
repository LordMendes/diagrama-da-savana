defmodule DiagramaSavana.Alvos do
  @moduledoc """
  Metas de alocação (**target allocation**) por classe macro, por carteira.
  """

  import Ecto.Query

  alias DiagramaSavana.Alvos.TargetAllocation
  alias DiagramaSavana.Carteiras.Portfolio
  alias DiagramaSavana.Repo

  def list_target_allocations(%Portfolio{id: portfolio_id}) do
    from(t in TargetAllocation,
      where: t.portfolio_id == ^portfolio_id,
      order_by: [asc: t.macro_class]
    )
    |> Repo.all()
  end

  def get_target_allocation(%Portfolio{id: portfolio_id}, id) do
    case Repo.get(TargetAllocation, id) do
      %TargetAllocation{portfolio_id: ^portfolio_id} = t -> {:ok, t}
      %TargetAllocation{} -> {:error, :not_found}
      nil -> {:error, :not_found}
    end
  end

  def create_target_allocation(%Portfolio{} = portfolio, attrs) when is_map(attrs) do
    %TargetAllocation{}
    |> TargetAllocation.changeset(Map.put(attrs, :portfolio_id, portfolio.id))
    |> Repo.insert()
  end

  def update_target_allocation(%TargetAllocation{} = row, attrs) do
    row
    |> TargetAllocation.changeset(attrs)
    |> Repo.update()
  end

  def delete_target_allocation(%TargetAllocation{} = row), do: Repo.delete(row)
end
