defmodule DiagramaSavanaWeb.API.V1.HoldingController do
  use DiagramaSavanaWeb, :api

  import Guardian.Plug, only: [current_resource: 1]

  alias DiagramaSavana.Ativos
  alias DiagramaSavana.Carteiras
  alias DiagramaSavana.Repo
  alias DiagramaSavanaWeb.API.V1.DomainJSON
  alias DiagramaSavanaWeb.ApiJSON

  def index(conn, %{"portfolio_id" => portfolio_id}) do
    user = current_resource(conn)

    case Carteiras.get_portfolio(user, portfolio_id) do
      {:ok, portfolio} ->
        holdings = Carteiras.list_holdings(portfolio)
        json(conn, %{data: Enum.map(holdings, &DomainJSON.holding/1)})

      {:error, :not_found} ->
        not_found(conn)
    end
  end

  def show(conn, %{"portfolio_id" => portfolio_id, "id" => holding_id}) do
    user = current_resource(conn)

    case Carteiras.get_holding(user, portfolio_id, holding_id) do
      {:ok, h} ->
        json(conn, %{data: DomainJSON.holding(h)})

      {:error, :not_found} ->
        not_found(conn)
    end
  end

  def create(conn, %{"portfolio_id" => portfolio_id} = params) do
    user = current_resource(conn)
    payload = holding_payload(params)

    with {:ok, portfolio} <- Carteiras.get_portfolio(user, portfolio_id),
         {:ok, asset} <- resolve_asset(payload),
         {:ok, h} <-
           Carteiras.create_holding(portfolio, %{
             asset_id: asset.id,
             quantity: payload[:quantity],
             average_price: payload[:average_price]
           }) do
      h = Repo.preload(h, :asset)

      conn
      |> put_status(:created)
      |> json(%{data: DomainJSON.holding(h)})
    else
      {:error, :not_found} ->
        not_found(conn)

      {:error, :invalid_payload} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          error: %{
            code: "payload_invalido",
            message: "Informe asset_id ou o par ticker e kind."
          }
        })

      {:error, %Ecto.Changeset{} = cs} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: ApiJSON.changeset_errors(cs)})
    end
  end

  def update(conn, %{"portfolio_id" => portfolio_id, "id" => holding_id} = params) do
    user = current_resource(conn)
    payload = holding_payload(params)

    with {:ok, h} <- Carteiras.get_holding(user, portfolio_id, holding_id),
         {:ok, updated} <-
           Carteiras.update_holding(h, %{
             quantity: payload[:quantity] || h.quantity,
             average_price: payload[:average_price] || h.average_price
           }) do
      updated = Repo.preload(updated, :asset)
      json(conn, %{data: DomainJSON.holding(updated)})
    else
      {:error, :not_found} ->
        not_found(conn)

      {:error, %Ecto.Changeset{} = cs} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: ApiJSON.changeset_errors(cs)})
    end
  end

  def delete(conn, %{"portfolio_id" => portfolio_id, "id" => holding_id}) do
    user = current_resource(conn)

    with {:ok, h} <- Carteiras.get_holding(user, portfolio_id, holding_id),
         {:ok, _} <- Carteiras.delete_holding(h) do
      send_resp(conn, :no_content, "")
    else
      {:error, :not_found} ->
        not_found(conn)

      {:error, _} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: %{code: "erro", message: "Não foi possível remover a posição."}})
    end
  end

  defp holding_payload(params) do
    p = params["holding"] || params["data"] || %{}

    %{
      asset_id: p["asset_id"] || p[:asset_id],
      ticker: p["ticker"] || p[:ticker],
      kind: p["kind"] || p[:kind],
      quantity: p["quantity"] || p[:quantity],
      average_price: p["average_price"] || p[:average_price]
    }
  end

  defp resolve_asset(%{asset_id: id}) when is_binary(id) and id != "" do
    case Ativos.get_asset(id) do
      nil -> {:error, :not_found}
      asset -> {:ok, asset}
    end
  end

  defp resolve_asset(%{ticker: t, kind: k}) when is_binary(t) and t != "" and not is_nil(k) do
    Ativos.get_or_create_asset(%{ticker: t, kind: normalize_kind(k)})
  end

  defp resolve_asset(_), do: {:error, :invalid_payload}

  defp normalize_kind(k) when is_binary(k), do: String.downcase(String.trim(k))
  defp normalize_kind(k) when is_atom(k), do: Atom.to_string(k)

  defp not_found(conn) do
    conn
    |> put_status(:not_found)
    |> json(%{error: %{code: "nao_encontrado", message: "Recurso não encontrado."}})
  end
end
