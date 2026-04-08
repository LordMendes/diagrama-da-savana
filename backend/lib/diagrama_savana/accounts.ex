defmodule DiagramaSavana.Accounts do
  @moduledoc """
  Contas de usuário: cadastro, credenciais e redefinição de senha.
  """

  import Ecto.Query

  alias DiagramaSavana.Accounts.{PasswordResetToken, User}
  alias DiagramaSavana.Repo

  @doc """
  Busca usuário por id (UUID binário ou string).
  """
  def get_user(id) when is_binary(id) do
    case Ecto.UUID.cast(id) do
      {:ok, uuid} -> Repo.get(User, uuid)
      :error -> nil
    end
  end

  def get_user_by_email(email) when is_binary(email) do
    email = String.downcase(String.trim(email))

    Repo.get_by(User, email: email)
  end

  @doc """
  Registra um novo usuário.
  """
  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Atualiza e-mail do usuário (perfil).
  """
  def update_user_profile(%User{} = user, attrs) when is_map(attrs) do
    user
    |> User.profile_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Autentica por email e senha em texto plano.
  """
  def authenticate_user(email, password)
      when is_binary(email) and is_binary(password) do
    user = get_user_by_email(email)

    cond do
      user && Bcrypt.verify_pass(password, user.password_hash) ->
        {:ok, user}

      user ->
        Bcrypt.no_user_verify()
        {:error, :invalid_credentials}

      true ->
        Bcrypt.no_user_verify()
        {:error, :invalid_credentials}
    end
  end

  @doc """
  Solicita redefinição de senha: cria token e dispara e-mail (se usuário existir).
  Retorna sempre `:ok` para evitar enumeração de e-mails.
  """
  def deliver_password_reset_instructions(email) when is_binary(email) do
    email = String.downcase(String.trim(email))

    if user = get_user_by_email(email) do
      {:ok, token_row} = create_password_reset_token(user)
      reset_url = password_reset_url(token_row.token)
      DiagramaSavana.Accounts.UserNotifier.deliver_password_reset_instructions(user, reset_url)
    end

    :ok
  end

  defp password_reset_url(token) do
    base = Application.get_env(:diagrama_savana, :public_app_url, "http://localhost:5173")
    String.trim_trailing(base, "/") <> "/redefinir-senha?token=" <> token
  end

  defp create_password_reset_token(%User{} = user) do
    ttl_minutes = Application.get_env(:diagrama_savana, :password_reset_ttl_minutes, 60)
    token = Ecto.UUID.generate()
    expires_at = DateTime.utc_now() |> DateTime.add(ttl_minutes * 60, :second)

    Repo.delete_all(from p in PasswordResetToken, where: p.user_id == ^user.id)

    %PasswordResetToken{}
    |> PasswordResetToken.changeset(%{
      user_id: user.id,
      token: token,
      expires_at: expires_at
    })
    |> Repo.insert()
  end

  @doc """
  Redefine a senha a partir do token opaco. Remove tokens do usuário após sucesso.
  """
  def reset_password_with_token(token, attrs) when is_binary(token) do
    now = DateTime.utc_now()

    query =
      from prt in PasswordResetToken,
        where: prt.token == ^token,
        where: prt.expires_at > ^now,
        preload: [:user]

    case Repo.one(query) do
      nil ->
        {:error, :invalid_or_expired_token}

      %PasswordResetToken{user: %User{} = user} = _prt ->
        result =
          user
          |> User.password_changeset(attrs)
          |> Repo.update()

        case result do
          {:ok, user} ->
            Repo.delete_all(from p in PasswordResetToken, where: p.user_id == ^user.id)
            {:ok, user}

          {:error, changeset} ->
            {:error, changeset}
        end
    end
  end
end
