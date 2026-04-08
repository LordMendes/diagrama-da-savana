defmodule DiagramaSavanaWeb.Router do
  use DiagramaSavanaWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {DiagramaSavanaWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Autenticação JWT (Guardian): header Authorization: Bearer <token>
  pipeline :api_auth do
    plug Guardian.Plug.Pipeline,
      module: DiagramaSavana.Accounts.Guardian,
      error_handler: DiagramaSavanaWeb.AuthErrorHandler

    plug Guardian.Plug.VerifyHeader, scheme: "Bearer"
    plug Guardian.Plug.EnsureAuthenticated
    plug Guardian.Plug.LoadResource
  end

  scope "/", DiagramaSavanaWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  scope "/api/v1", DiagramaSavanaWeb.API.V1, as: :api_v1 do
    pipe_through :api

    post "/registration", RegistrationController, :create
    post "/session", SessionController, :create
    post "/password-reset", PasswordResetController, :create
    put "/password-reset", PasswordResetController, :update

    pipe_through :api_auth

    post "/session/renew", SessionController, :renew
    delete "/session", SessionController, :delete
    get "/me", MeController, :show
    patch "/me", MeController, :update

    # Domínio: carteiras, ativos, metas e nota de resistência (contrato JSON — ver DomainJSON)
    get "/portfolios", PortfolioController, :index
    post "/portfolios", PortfolioController, :create
    get "/portfolios/:portfolio_id/summary", PortfolioController, :summary
    post "/portfolios/:portfolio_id/simulacao_aporte", SimulacaoAporteController, :create
    post "/portfolios/:portfolio_id/simulacao_aporte/aplicar", SimulacaoAporteController, :aplicar
    get "/portfolios/:portfolio_id/aportes", AporteController, :index
    post "/portfolios/:portfolio_id/aportes", AporteController, :create
    get "/portfolios/:id", PortfolioController, :show
    patch "/portfolios/:id", PortfolioController, :update
    put "/portfolios/:id", PortfolioController, :update
    delete "/portfolios/:id", PortfolioController, :delete

    get "/assets", AssetController, :index
    post "/assets", AssetController, :create
    get "/assets/:id", AssetController, :show

    get "/portfolios/:portfolio_id/holdings", HoldingController, :index
    post "/portfolios/:portfolio_id/holdings", HoldingController, :create
    get "/portfolios/:portfolio_id/holdings/:id", HoldingController, :show
    patch "/portfolios/:portfolio_id/holdings/:id", HoldingController, :update
    delete "/portfolios/:portfolio_id/holdings/:id", HoldingController, :delete

    get "/portfolios/:portfolio_id/target_allocations", TargetAllocationController, :index
    post "/portfolios/:portfolio_id/target_allocations", TargetAllocationController, :create
    get "/portfolios/:portfolio_id/target_allocations/:id", TargetAllocationController, :show
    patch "/portfolios/:portfolio_id/target_allocations/:id", TargetAllocationController, :update
    delete "/portfolios/:portfolio_id/target_allocations/:id", TargetAllocationController, :delete

    get "/resistance_criteria", ResistanceCriteriaController, :index
    get "/resistance_profiles", ResistanceProfileController, :index
    get "/resistance_profiles/:asset_id", ResistanceProfileController, :show
    put "/resistance_profiles/:asset_id", ResistanceProfileController, :upsert
    delete "/resistance_profiles/:asset_id", ResistanceProfileController, :delete

    # Mercado (brapi.dev) — proxy com cache e rate limit no backend
    get "/market/search", MarketController, :search
    get "/market/quotes/:ticker", MarketController, :quote
  end
end
