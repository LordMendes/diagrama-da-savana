defmodule DiagramaSavana.Aportes do
  @moduledoc """
  Registro simples de **aportes** por carteira (valor, data, observação).
  """

  import Ecto.Query

  alias DiagramaSavana.Aportes.Aporte
  alias DiagramaSavana.Carteiras.Portfolio
  alias DiagramaSavana.Repo

  def list_aportes(%Portfolio{id: portfolio_id}, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)

    from(a in Aporte,
      where: a.portfolio_id == ^portfolio_id,
      order_by: [desc: a.occurred_on, desc: a.inserted_at],
      limit: ^limit
    )
    |> Repo.all()
  end

  def create_aporte(%Portfolio{} = portfolio, attrs) when is_map(attrs) do
    %Aporte{}
    |> Aporte.changeset(Map.put(attrs, :portfolio_id, portfolio.id))
    |> Repo.insert()
  end
end
