# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :diagrama_savana,
  ecto_repos: [DiagramaSavana.Repo],
  generators: [timestamp_type: :utc_datetime, binary_id: true]

# Configure the endpoint
config :diagrama_savana, DiagramaSavanaWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: DiagramaSavanaWeb.ErrorHTML, json: DiagramaSavanaWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: DiagramaSavana.PubSub,
  live_view: [signing_salt: "t5YQgB2r"]

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Auth (Guardian JWT) — secret overridden per env (test/dev/prod)
config :diagrama_savana, DiagramaSavana.Accounts.Guardian,
  issuer: "diagrama_savana",
  secret_key: "dev_guardian_secret_replace_in_prod_min_32_chars_01"

config :diagrama_savana, :auth,
  access_token_ttl_minutes: 15,
  renewal_token_ttl_days: 7

config :diagrama_savana, :password_reset_ttl_minutes, 60

# URL público do frontend (links em e-mails de redefinição de senha)
config :diagrama_savana, :public_app_url, "http://localhost:5173"

config :diagrama_savana, DiagramaSavana.Mailer, adapter: Swoosh.Adapters.Local

# Req já é dependência do projeto; evita exigir :hackney no runtime do Swoosh.
config :swoosh, :api_client, Swoosh.ApiClient.Req

config :diagrama_savana, :mailer_from_email, "nao-responda@localhost"
config :diagrama_savana, :mailer_from_name, "Diagrama da Savana"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
