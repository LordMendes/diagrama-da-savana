defmodule DiagramaSavana.Repo do
  use Ecto.Repo,
    otp_app: :diagrama_savana,
    adapter: Ecto.Adapters.Postgres
end
