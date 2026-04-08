defmodule DiagramaSavana.Alvos.TargetAllocation do
  use Ecto.Schema
  import Ecto.Changeset

  @macro_classes ~w(renda_fixa renda_variavel fiis internacional cripto outros)a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "target_allocations" do
    field :macro_class, Ecto.Enum, values: @macro_classes
    field :target_percent, :decimal

    belongs_to :portfolio, DiagramaSavana.Carteiras.Portfolio

    timestamps(type: :utc_datetime)
  end

  def macro_classes, do: @macro_classes

  def changeset(target_allocation, attrs) do
    target_allocation
    |> cast(attrs, [:macro_class, :target_percent, :portfolio_id])
    |> validate_required([:macro_class, :target_percent, :portfolio_id],
      message: "não pode ficar em branco"
    )
    |> validate_number(:target_percent,
      greater_than_or_equal_to: Decimal.new(0),
      less_than_or_equal_to: Decimal.new(100),
      message: "deve estar entre 0 e 100"
    )
    |> foreign_key_constraint(:portfolio_id)
    |> unique_constraint([:portfolio_id, :macro_class],
      name: :target_allocations_portfolio_id_macro_class_index,
      message: "já existe meta para esta classe"
    )
  end
end
