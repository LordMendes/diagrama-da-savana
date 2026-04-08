defmodule DiagramaSavana.Resistencia.Profile do
  @moduledoc """
  Nota de Resistência por usuário e ativo.

  `criteria_stub` guarda o mapa critério → -1, 0 ou +1; `computed_score` é a soma limitada entre **-5 e +10**.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "resistance_profiles" do
    field :computed_score, :integer
    field :criteria_stub, :map, default: %{}

    belongs_to :user, DiagramaSavana.Accounts.User
    belongs_to :asset, DiagramaSavana.Ativos.Asset

    timestamps(type: :utc_datetime)
  end

  def changeset(profile, attrs) do
    profile
    |> cast(attrs, [:computed_score, :criteria_stub, :user_id, :asset_id])
    |> validate_required([:user_id, :asset_id], message: "não pode ficar em branco")
    |> validate_computed_score_range()
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:asset_id)
    |> unique_constraint([:user_id, :asset_id],
      name: :resistance_profiles_user_id_asset_id_index,
      message: "já existe nota para este ativo"
    )
  end

  defp validate_computed_score_range(changeset) do
    case get_field(changeset, :computed_score) do
      nil ->
        changeset

      n when is_integer(n) and n >= -5 and n <= 10 ->
        changeset

      _ ->
        add_error(changeset, :computed_score, "deve estar entre -5 e 10")
    end
  end
end
