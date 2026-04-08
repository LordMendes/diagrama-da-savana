defmodule DiagramaSavana.Carteiras.Holding do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "holdings" do
    field :quantity, :decimal
    field :average_price, :decimal

    belongs_to :portfolio, DiagramaSavana.Carteiras.Portfolio
    belongs_to :asset, DiagramaSavana.Ativos.Asset

    timestamps(type: :utc_datetime)
  end

  def changeset(holding, attrs) do
    holding
    |> cast(attrs, [:quantity, :average_price, :portfolio_id, :asset_id])
    |> validate_required([:quantity, :average_price, :portfolio_id, :asset_id],
      message: "não pode ficar em branco"
    )
    |> validate_number(:quantity,
      greater_than: Decimal.new(0),
      message: "deve ser maior que zero"
    )
    |> validate_number(:average_price,
      greater_than_or_equal_to: Decimal.new(0),
      message: "deve ser zero ou positivo"
    )
    |> foreign_key_constraint(:portfolio_id)
    |> foreign_key_constraint(:asset_id)
    |> unique_constraint([:portfolio_id, :asset_id],
      name: :holdings_portfolio_id_asset_id_index,
      message: "este ativo já está na carteira"
    )
  end
end
