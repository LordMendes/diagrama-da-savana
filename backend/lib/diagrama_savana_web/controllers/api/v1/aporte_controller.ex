defmodule DiagramaSavanaWeb.API.V1.AporteController do
  use DiagramaSavanaWeb, :api

  import Guardian.Plug, only: [current_resource: 1]

  alias DiagramaSavana.Aportes
  alias DiagramaSavana.Carteiras
  alias DiagramaSavanaWeb.API.V1.DomainJSON
  alias DiagramaSavanaWeb.ApiJSON

  def index(conn, %{"portfolio_id" => portfolio_id}) do
    user = current_resource(conn)

    case Carteiras.get_portfolio(user, portfolio_id) do
      {:ok, p} ->
        rows = Aportes.list_aportes(p, limit: 50)
        json(conn, %{data: Enum.map(rows, &DomainJSON.aporte/1)})

      {:error, :not_found} ->
        not_found(conn)
    end
  end

  def create(conn, %{"portfolio_id" => portfolio_id} = params) do
    user = current_resource(conn)
    attrs = aporte_attrs(params)

    case Carteiras.get_portfolio(user, portfolio_id) do
      {:ok, p} ->
        case Aportes.create_aporte(p, attrs) do
          {:ok, a} ->
            conn
            |> put_status(:created)
            |> json(%{data: DomainJSON.aporte(a)})

          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{errors: ApiJSON.changeset_errors(changeset)})
        end

      {:error, :not_found} ->
        not_found(conn)
    end
  end

  defp aporte_attrs(params) do
    p = params["aporte"] || params["data"] || %{}

    %{
      amount: p["amount"] || p[:amount],
      note: p["note"] || p[:note],
      occurred_on: p["occurred_on"] || p[:occurred_on]
    }
    |> Enum.reject(fn {_, v} -> is_nil(v) end)
    |> Map.new()
  end

  defp not_found(conn) do
    conn
    |> put_status(:not_found)
    |> json(%{error: %{code: "nao_encontrado", message: "Carteira não encontrada."}})
  end
end
