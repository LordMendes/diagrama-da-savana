defmodule DiagramaSavanaWeb.API.V1.PortfolioController do
  use DiagramaSavanaWeb, :api

  import Guardian.Plug, only: [current_resource: 1]

  alias DiagramaSavana.Carteiras
  alias DiagramaSavanaWeb.API.V1.DomainJSON
  alias DiagramaSavanaWeb.ApiJSON

  def index(conn, _params) do
    user = current_resource(conn)
    _ = Carteiras.ensure_default_portfolio(user)
    portfolios = Carteiras.list_portfolios(user)
    json(conn, %{data: Enum.map(portfolios, &DomainJSON.portfolio/1)})
  end

  def summary(conn, %{"portfolio_id" => portfolio_id}) do
    user = current_resource(conn)

    case Carteiras.get_portfolio(user, portfolio_id) do
      {:ok, p} ->
        s = Carteiras.portfolio_summary(p)
        json(conn, %{data: DomainJSON.portfolio_summary(s)})

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: %{code: "nao_encontrado", message: "Carteira não encontrada."}})
    end
  end

  def show(conn, %{"id" => id}) do
    user = current_resource(conn)

    case Carteiras.get_portfolio(user, id) do
      {:ok, p} ->
        json(conn, %{data: DomainJSON.portfolio(p)})

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: %{code: "nao_encontrado", message: "Carteira não encontrada."}})
    end
  end

  def create(conn, params) do
    user = current_resource(conn)
    attrs = portfolio_attrs(params)

    case Carteiras.create_portfolio(user, attrs) do
      {:ok, p} ->
        conn
        |> put_status(:created)
        |> json(%{data: DomainJSON.portfolio(p)})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: ApiJSON.changeset_errors(changeset)})
    end
  end

  def update(conn, %{"id" => id} = params) do
    user = current_resource(conn)

    with {:ok, p} <- Carteiras.get_portfolio(user, id),
         {:ok, updated} <- Carteiras.update_portfolio(p, portfolio_attrs(params)) do
      json(conn, %{data: DomainJSON.portfolio(updated)})
    else
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: %{code: "nao_encontrado", message: "Carteira não encontrada."}})

      {:error, %Ecto.Changeset{} = cs} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: ApiJSON.changeset_errors(cs)})
    end
  end

  def delete(conn, %{"id" => id}) do
    user = current_resource(conn)

    with {:ok, p} <- Carteiras.get_portfolio(user, id),
         {:ok, _} <- Carteiras.delete_portfolio(p) do
      send_resp(conn, :no_content, "")
    else
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: %{code: "nao_encontrado", message: "Carteira não encontrada."}})

      {:error, :default_readonly} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          error: %{
            code: "carteira_padrao",
            message: "A carteira principal não pode ser excluída."
          }
        })
    end
  end

  defp portfolio_attrs(params) do
    p = params["portfolio"] || params["data"] || %{}

    %{name: p["name"] || p[:name]}
    |> Enum.reject(fn {_, v} -> is_nil(v) end)
    |> Map.new()
  end
end
