defmodule DiagramaSavana.Accounts.UserNotifier do
  @moduledoc """
  E-mails transacionais de conta (Swoosh).
  """

  import Swoosh.Email

  alias DiagramaSavana.Accounts.User
  alias DiagramaSavana.Mailer

  @doc """
  Envia instruções de redefinição de senha.
  """
  def deliver_password_reset_instructions(%User{} = user, reset_url) do
    email =
      new()
      |> to(user.email)
      |> from({from_name(), from_email()})
      |> subject("Redefinição de senha — Diagrama da Savana")
      |> text_body("""
      Olá,

      Para definir uma nova senha, acesse o link abaixo (válido por tempo limitado):

      #{reset_url}

      Se você não solicitou esta alteração, ignore este e-mail.

      — Diagrama da Savana
      """)
      |> html_body("""
      <p>Olá,</p>
      <p>Para definir uma nova senha, clique no link abaixo (válido por tempo limitado):</p>
      <p><a href="#{reset_url}">Redefinir senha</a></p>
      <p>Se você não solicitou esta alteração, ignore este e-mail.</p>
      <p>— Diagrama da Savana</p>
      """)

    Mailer.deliver(email)
  end

  defp from_email do
    Application.get_env(:diagrama_savana, :mailer_from_email, "nao-responda@localhost")
  end

  defp from_name do
    Application.get_env(:diagrama_savana, :mailer_from_name, "Diagrama da Savana")
  end
end
