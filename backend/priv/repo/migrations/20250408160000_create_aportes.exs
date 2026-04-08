defmodule DiagramaSavana.Repo.Migrations.CreateAportes do
  use Ecto.Migration

  def change do
    create table(:aportes, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :portfolio_id, references(:portfolios, type: :binary_id, on_delete: :delete_all),
        null: false

      add :amount, :decimal, null: false
      add :note, :string
      add :occurred_on, :date, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:aportes, [:portfolio_id])
    create index(:aportes, [:occurred_on])
  end
end
