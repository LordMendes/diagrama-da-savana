defmodule DiagramaSavana.Ativos do
  @moduledoc """
  Catálogo de **ativos** (ticker + tipo) referenciados pelas posições e pela nota de resistência.
  """

  import Ecto.Query

  alias DiagramaSavana.Ativos.Asset
  alias DiagramaSavana.Repo

  def list_assets do
    from(a in Asset, order_by: [asc: a.ticker]) |> Repo.all()
  end

  def get_asset(id), do: Repo.get(Asset, id)

  def get_asset!(id) do
    case get_asset(id) do
      %Asset{} = a -> a
      nil -> raise Ecto.NoResultsError, queryable: Asset
    end
  end

  def get_asset_by_ticker(ticker) when is_binary(ticker) do
    t = ticker |> String.trim() |> String.upcase()
    Repo.get_by(Asset, ticker: t)
  end

  @doc """
  Cria um ativo ou retorna o existente com o mesmo ticker (idempotente).
  """
  def get_or_create_asset(attrs) when is_map(attrs) do
    ticker =
      (attrs[:ticker] || attrs["ticker"] || "")
      |> to_string()
      |> String.trim()
      |> String.upcase()

    kind = attrs[:kind] || attrs["kind"]

    case get_asset_by_ticker(ticker) do
      %Asset{} = a -> {:ok, a}
      nil -> create_asset(%{ticker: ticker, kind: kind})
    end
  end

  def create_asset(attrs) when is_map(attrs) do
    %Asset{}
    |> Asset.changeset(attrs)
    |> Repo.insert()
  end

  def update_asset(%Asset{} = asset, attrs) do
    asset
    |> Asset.changeset(attrs)
    |> Repo.update()
  end
end
