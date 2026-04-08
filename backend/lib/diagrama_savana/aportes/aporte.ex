defmodule DiagramaSavana.Aportes.Aporte do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "aportes" do
    field :amount, :decimal
    field :note, :string
    field :occurred_on, :date

    belongs_to :portfolio, DiagramaSavana.Carteiras.Portfolio

    timestamps(type: :utc_datetime)
  end

  def changeset(aporte, attrs) do
    aporte
    |> cast(attrs, [:amount, :note, :occurred_on, :portfolio_id])
    |> validate_required([:amount, :occurred_on, :portfolio_id],
      message: "não pode ficar em branco"
    )
    |> validate_number(:amount,
      greater_than: Decimal.new(0),
      message: "deve ser maior que zero"
    )
    |> foreign_key_constraint(:portfolio_id)
  end
end
