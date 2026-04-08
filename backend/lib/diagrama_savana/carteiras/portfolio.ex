defmodule DiagramaSavana.Carteiras.Portfolio do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "portfolios" do
    field :name, :string, default: "Principal"

    belongs_to :user, DiagramaSavana.Accounts.User
    has_many :holdings, DiagramaSavana.Carteiras.Holding
    has_many :target_allocations, DiagramaSavana.Alvos.TargetAllocation

    timestamps(type: :utc_datetime)
  end

  def create_changeset(portfolio, attrs) do
    portfolio
    |> cast(attrs, [:name, :user_id])
    |> validate_required([:user_id], message: "não pode ficar em branco")
    |> default_name_if_blank()
    |> validate_length(:name, min: 1, max: 120)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint([:user_id, :name],
      name: :portfolios_user_id_name_index,
      message: "já existe uma carteira com este nome"
    )
  end

  def update_changeset(%__MODULE__{} = portfolio, attrs) do
    portfolio
    |> cast(attrs, [:name])
    |> validate_required([:name], message: "não pode ficar em branco")
    |> validate_length(:name, min: 1, max: 120)
    |> unique_constraint([:user_id, :name],
      name: :portfolios_user_id_name_index,
      message: "já existe uma carteira com este nome"
    )
  end

  defp default_name_if_blank(changeset) do
    case get_change(changeset, :name) do
      nil -> put_change(changeset, :name, "Principal")
      "" -> put_change(changeset, :name, "Principal")
      _ -> changeset
    end
  end
end
