defmodule DiagramaSavana.Repo.Migrations.CreatePortfoliosAssetsHoldingsTargetsResistance do
  use Ecto.Migration

  def change do
    create table(:portfolios, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :name, :string, null: false, default: "Principal"

      timestamps(type: :utc_datetime)
    end

    create index(:portfolios, [:user_id])
    create unique_index(:portfolios, [:user_id, :name])

    create table(:assets, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :ticker, :string, null: false
      add :kind, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:assets, [:ticker])

    create table(:holdings, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :portfolio_id, references(:portfolios, type: :binary_id, on_delete: :delete_all),
        null: false

      add :asset_id, references(:assets, type: :binary_id, on_delete: :restrict), null: false
      add :quantity, :decimal, null: false
      add :average_price, :decimal, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:holdings, [:portfolio_id, :asset_id])
    create index(:holdings, [:asset_id])

    create table(:target_allocations, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :portfolio_id, references(:portfolios, type: :binary_id, on_delete: :delete_all),
        null: false

      add :macro_class, :string, null: false
      add :target_percent, :decimal, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:target_allocations, [:portfolio_id, :macro_class])
    create index(:target_allocations, [:portfolio_id])

    create table(:resistance_profiles, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :asset_id, references(:assets, type: :binary_id, on_delete: :delete_all), null: false

      add :computed_score, :integer
      add :criteria_stub, :map, null: false, default: %{}

      timestamps(type: :utc_datetime)
    end

    create unique_index(:resistance_profiles, [:user_id, :asset_id])
    create index(:resistance_profiles, [:asset_id])
  end
end
