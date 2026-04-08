defmodule DiagramaSavanaWeb.ApiJSON do
  @moduledoc """
  Formata erros de changeset para respostas JSON (mensagens em pt-BR quando definidas no schema).
  """

  def changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{" <> to_string(key) <> "}", to_string(value))
      end)
    end)
  end
end
