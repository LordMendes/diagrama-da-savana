defmodule DiagramaSavana.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "users" do
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :password_confirmation, :string, virtual: true, redact: true
    field :password_hash, :string, redact: true

    has_many :portfolios, DiagramaSavana.Carteiras.Portfolio
    has_many :resistance_profiles, DiagramaSavana.Resistencia.Profile

    timestamps(type: :utc_datetime)
  end

  @doc """
  Cadastro com hash de senha (Comeonin/Bcrypt).
  """
  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password, :password_confirmation])
    |> update_change(:email, fn
      nil -> nil
      e -> e |> String.trim() |> String.downcase()
    end)
    |> validate_required([:email, :password, :password_confirmation],
      message: "não pode ficar em branco"
    )
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "formato inválido")
    |> validate_length(:email,
      max: 160,
      message: "deve ter no máximo %{count} caracteres"
    )
    |> unique_constraint(:email, message: "já está em uso")
    |> validate_length(:password,
      min: 8,
      count: :bytes,
      message: "deve ter no mínimo %{count} bytes"
    )
    |> validate_length(:password,
      max: 72,
      count: :bytes,
      message: "deve ter no máximo %{count} bytes"
    )
    |> validate_confirmation(:password, message: "não confere com a confirmação")
    |> maybe_hash_password()
  end

  @doc """
  Atualização de e-mail (perfil autenticado).
  """
  def profile_changeset(user, attrs) do
    user
    |> cast(attrs, [:email])
    |> update_change(:email, fn
      nil -> nil
      e -> e |> String.trim() |> String.downcase()
    end)
    |> validate_required([:email], message: "não pode ficar em branco")
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "formato inválido")
    |> validate_length(:email,
      max: 160,
      message: "deve ter no máximo %{count} caracteres"
    )
    |> unique_constraint(:email, message: "já está em uso")
  end

  @doc """
  Atualização de senha (fluxo de redefinição).
  """
  def password_changeset(user, attrs) do
    user
    |> cast(attrs, [:password, :password_confirmation])
    |> validate_required([:password, :password_confirmation],
      message: "não pode ficar em branco"
    )
    |> validate_length(:password,
      min: 8,
      count: :bytes,
      message: "deve ter no mínimo %{count} bytes"
    )
    |> validate_length(:password,
      max: 72,
      count: :bytes,
      message: "deve ter no máximo %{count} bytes"
    )
    |> validate_confirmation(:password, message: "não confere com a confirmação")
    |> maybe_hash_password()
  end

  defp maybe_hash_password(changeset) do
    password = get_change(changeset, :password)

    if password && changeset.valid? do
      changeset
      |> put_change(:password_hash, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
      |> delete_change(:password_confirmation)
    else
      changeset
    end
  end
end
