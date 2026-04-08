import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :diagrama_savana, DiagramaSavana.Repo,
  username: System.get_env("DATABASE_USER", "postgres"),
  password: System.get_env("DATABASE_PASSWORD", "postgres"),
  hostname: System.get_env("DATABASE_HOST", "localhost"),
  port: String.to_integer(System.get_env("DATABASE_PORT", "5433")),
  database:
    System.get_env("DATABASE_TEST_NAME") ||
      "diagrama_savana_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :diagrama_savana, DiagramaSavanaWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "fbkc42u9iy0K0Dc0F2EDMpNP+Ew7/3XY0Epujizn/laYfqUeXWfQF9/XuL8UpkPP",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true

config :diagrama_savana, DiagramaSavana.Mailer, adapter: Swoosh.Adapters.Test

config :diagrama_savana, DiagramaSavana.Accounts.Guardian,
  secret_key: "test_guardian_secret_key_at_least_thirty_two_bytes_ok"

# brapi: mock HTTP so CI never calls brapi.dev (see DiagramaSavana.Brapi.Client)
config :diagrama_savana, :brapi_transport, DiagramaSavana.Brapi.TransportMock
