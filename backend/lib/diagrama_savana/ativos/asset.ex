defmodule DiagramaSavana.Ativos.Asset do
  use Ecto.Schema
  import Ecto.Changeset

  @kinds ~w(acao fii etf renda_fixa internacional cripto outro)a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "assets" do
    field :ticker, :string
    field :kind, Ecto.Enum, values: @kinds

    has_many :holdings, DiagramaSavana.Carteiras.Holding
    has_many :resistance_profiles, DiagramaSavana.Resistencia.Profile, foreign_key: :asset_id

    timestamps(type: :utc_datetime)
  end

  def kinds, do: @kinds

  def changeset(asset, attrs) do
    asset
    |> cast(attrs, [:ticker, :kind])
    |> update_change(:ticker, fn
      nil -> nil
      t -> t |> String.trim() |> String.upcase()
    end)
    |> validate_required([:ticker, :kind], message: "não pode ficar em branco")
    |> validate_length(:ticker, min: 1, max: 32)
    |> unique_constraint(:ticker, message: "já está cadastrado")
  end
end
