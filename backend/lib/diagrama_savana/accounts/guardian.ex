defmodule DiagramaSavana.Accounts.Guardian do
  use Guardian, otp_app: :diagrama_savana

  alias DiagramaSavana.Accounts

  @impl Guardian
  def subject_for_token(%{id: id}, _claims), do: {:ok, to_string(id)}

  def subject_for_token(_, _), do: {:error, :invalid_resource}

  @impl Guardian
  def resource_from_claims(%{"sub" => subject}) do
    case Accounts.get_user(subject) do
      nil -> {:error, :resource_not_found}
      user -> {:ok, user}
    end
  end

  def resource_from_claims(_), do: {:error, :invalid_claims}
end
