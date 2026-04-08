import Config

# Dev/test: load `backend/.env` into the OS env so `mix ecto.*` and the app see
# DATABASE_URL, BRAPI_*, etc. (Mix does not read `.env` by itself.) Path is
# relative to this file so it works regardless of the current working directory.
if config_env() in [:dev, :test] do
  env_file = Path.expand("../.env", __DIR__)

  if File.exists?(env_file) do
    {:ok, vars} = Dotenvy.source([System.get_env(), env_file, System.get_env()])
    System.put_env(vars)
  end
end

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/diagrama_savana start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :diagrama_savana, DiagramaSavanaWeb.Endpoint, server: true
end

config :diagrama_savana, DiagramaSavanaWeb.Endpoint,
  http: [port: String.to_integer(System.get_env("PORT", "4000"))]

# brapi.dev client (all environments; override via env)
# Token: BRAPI_API_TOKEN or BRAPI_TOKEN (same meaning; first wins when both set in env)
config :diagrama_savana, :brapi,
  base_url: System.get_env("BRAPI_BASE_URL", "https://brapi.dev/api"),
  api_token: System.get_env("BRAPI_API_TOKEN") || System.get_env("BRAPI_TOKEN")

config :diagrama_savana, :brapi_rate_limit,
  max_requests_per_minute: String.to_integer(System.get_env("BRAPI_RATE_LIMIT_PER_MINUTE", "60"))

config :diagrama_savana, :brapi_cache,
  default_ttl_seconds: String.to_integer(System.get_env("BRAPI_CACHE_TTL_SECONDS", "60"))

# Optional DATABASE_URL for dev/test (overrides dev.exs / test.exs repo keys when set)
if config_env() in [:dev, :test] do
  case System.get_env("DATABASE_URL") do
    nil -> :ok
    url -> config :diagrama_savana, DiagramaSavana.Repo, url: url
  end
end

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :diagrama_savana, DiagramaSavana.Repo,
    # ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    # For machines with several cores, consider starting multiple pools of `pool_size`
    # pool_count: 4,
    socket_options: maybe_ipv6

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  guardian_secret_key =
    System.get_env("GUARDIAN_SECRET_KEY") ||
      raise """
      environment variable GUARDIAN_SECRET_KEY is missing.
      Use a long random string (at least 32 bytes), e.g. mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"

  config :diagrama_savana, :public_app_url, System.get_env("PUBLIC_APP_URL") || "https://#{host}"

  cors_fallback = System.get_env("PUBLIC_APP_URL") || "https://#{host}"

  cors_origins =
    case System.get_env("CORS_ALLOWED_ORIGINS") do
      nil ->
        [cors_fallback]

      "" ->
        [cors_fallback]

      origins_str ->
        origins_str
        |> String.split(",", trim: true)
        |> Enum.map(&String.trim/1)
        |> Enum.reject(&(&1 == ""))
        |> case do
          [] -> [cors_fallback]
          list -> list
        end
    end

  config :cors_plug,
    origin: cors_origins,
    credentials: true

  if mailer_from = System.get_env("MAILER_FROM_EMAIL") do
    config :diagrama_savana, :mailer_from_email, mailer_from
  end

  if mailer_name = System.get_env("MAILER_FROM_NAME") do
    config :diagrama_savana, :mailer_from_name, mailer_name
  end

  config :diagrama_savana, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :diagrama_savana, DiagramaSavana.Accounts.Guardian, secret_key: guardian_secret_key

  config :diagrama_savana, DiagramaSavanaWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/bandit/Bandit.html#t:options/0
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0}
    ],
    secret_key_base: secret_key_base

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :diagrama_savana, DiagramaSavanaWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your config/prod.exs,
  # ensuring no data is ever sent via http, always redirecting to https:
  #
  #     config :diagrama_savana, DiagramaSavanaWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.
end
