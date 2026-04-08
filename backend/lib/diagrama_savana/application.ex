defmodule DiagramaSavana.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    :ok = DiagramaSavana.Brapi.RateLimiter.ensure_table()
    :ok = DiagramaSavana.Brapi.Cache.ensure_table()
    :ok = DiagramaSavana.Aportes.SimulacaoCache.ensure_table()

    children = [
      DiagramaSavanaWeb.Telemetry,
      DiagramaSavana.Repo,
      {DNSCluster, query: Application.get_env(:diagrama_savana, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: DiagramaSavana.PubSub},
      # Start a worker by calling: DiagramaSavana.Worker.start_link(arg)
      # {DiagramaSavana.Worker, arg},
      # Start to serve requests, typically the last entry
      DiagramaSavanaWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DiagramaSavana.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DiagramaSavanaWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
