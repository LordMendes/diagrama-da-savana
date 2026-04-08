defmodule DiagramaSavana.Accounts.PasswordResetToken do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "password_reset_tokens" do
    field :token, :string
    field :expires_at, :utc_datetime
    belongs_to :user, DiagramaSavana.Accounts.User

    timestamps(updated_at: false, type: :utc_datetime)
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:token, :expires_at, :user_id])
    |> validate_required([:token, :expires_at, :user_id])
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:token)
  end
end
