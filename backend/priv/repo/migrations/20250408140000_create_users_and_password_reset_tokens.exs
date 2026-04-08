defmodule DiagramaSavana.Repo.Migrations.CreateUsersAndPasswordResetTokens do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :string, null: false
      add :password_hash, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:email])

    create table(:password_reset_tokens, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :token, :string, null: false
      add :expires_at, :utc_datetime, null: false

      timestamps(updated_at: false, type: :utc_datetime)
    end

    create unique_index(:password_reset_tokens, [:token])
    create index(:password_reset_tokens, [:user_id])
  end
end
