defmodule DiagramaSavanaWeb.API.V1.TargetAllocationController do
  use DiagramaSavanaWeb, :api

  import Guardian.Plug, only: [current_resource: 1]

  alias DiagramaSavana.Alvos
  alias DiagramaSavana.Carteiras
  alias DiagramaSavanaWeb.API.V1.DomainJSON
  alias DiagramaSavanaWeb.ApiJSON

  def index(conn, %{"portfolio_id" => portfolio_id}) do
    user = current_resource(conn)

    case Carteiras.get_portfolio(user, portfolio_id) do
      {:ok, portfolio} ->
        rows = Alvos.list_target_allocations(portfolio)
        json(conn, %{data: Enum.map(rows, &DomainJSON.target_allocation/1)})

      {:error, :not_found} ->
        not_found(conn)
    end
  end

  def show(conn, %{"portfolio_id" => portfolio_id, "id" => id}) do
    user = current_resource(conn)

    with {:ok, portfolio} <- Carteiras.get_portfolio(user, portfolio_id),
         {:ok, row} <- Alvos.get_target_allocation(portfolio, id) do
      json(conn, %{data: DomainJSON.target_allocation(row)})
    else
      {:error, :not_found} ->
        not_found(conn)
    end
  end

  def create(conn, %{"portfolio_id" => portfolio_id} = params) do
    user = current_resource(conn)
    attrs = target_attrs(params)

    case Carteiras.get_portfolio(user, portfolio_id) do
      {:ok, portfolio} ->
        case Alvos.create_target_allocation(portfolio, attrs) do
          {:ok, row} ->
            conn
            |> put_status(:created)
            |> json(%{data: DomainJSON.target_allocation(row)})

          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{errors: ApiJSON.changeset_errors(changeset)})
        end

      {:error, :not_found} ->
        not_found(conn)
    end
  end

  def update(conn, %{"portfolio_id" => portfolio_id, "id" => id} = params) do
    user = current_resource(conn)
    attrs = target_attrs(params)

    with {:ok, portfolio} <- Carteiras.get_portfolio(user, portfolio_id),
         {:ok, row} <- Alvos.get_target_allocation(portfolio, id),
         {:ok, updated} <- Alvos.update_target_allocation(row, attrs) do
      json(conn, %{data: DomainJSON.target_allocation(updated)})
    else
      {:error, :not_found} ->
        not_found(conn)

      {:error, %Ecto.Changeset{} = cs} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: ApiJSON.changeset_errors(cs)})
    end
  end

  def delete(conn, %{"portfolio_id" => portfolio_id, "id" => id}) do
    user = current_resource(conn)

    with {:ok, portfolio} <- Carteiras.get_portfolio(user, portfolio_id),
         {:ok, row} <- Alvos.get_target_allocation(portfolio, id),
         {:ok, _} <- Alvos.delete_target_allocation(row) do
      send_resp(conn, :no_content, "")
    else
      {:error, :not_found} ->
        not_found(conn)
    end
  end

  defp target_attrs(params) do
    p = params["target_allocation"] || params["data"] || %{}

    %{
      macro_class: normalize_macro(p["macro_class"] || p[:macro_class]),
      target_percent: p["target_percent"] || p[:target_percent]
    }
    |> Enum.reject(fn {_, v} -> is_nil(v) end)
    |> Map.new()
  end

  defp normalize_macro(nil), do: nil

  defp normalize_macro(m) when is_binary(m) do
    m |> String.trim() |> String.downcase()
  end

  defp normalize_macro(m) when is_atom(m), do: Atom.to_string(m)

  defp not_found(conn) do
    conn
    |> put_status(:not_found)
    |> json(%{error: %{code: "nao_encontrado", message: "Recurso não encontrado."}})
  end
end
