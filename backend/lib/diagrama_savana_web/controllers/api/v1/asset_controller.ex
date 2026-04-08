defmodule DiagramaSavanaWeb.API.V1.AssetController do
  use DiagramaSavanaWeb, :api

  import Guardian.Plug, only: [current_resource: 1]

  alias DiagramaSavana.Ativos
  alias DiagramaSavanaWeb.API.V1.DomainJSON
  alias DiagramaSavanaWeb.ApiJSON

  def index(conn, _params) do
    _user = current_resource(conn)
    assets = Ativos.list_assets()
    json(conn, %{data: Enum.map(assets, &DomainJSON.asset/1)})
  end

  def show(conn, %{"id" => id}) do
    case Ativos.get_asset(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: %{code: "nao_encontrado", message: "Ativo não encontrado."}})

      asset ->
        json(conn, %{data: DomainJSON.asset(asset)})
    end
  end

  def create(conn, params) do
    _user = current_resource(conn)
    attrs = asset_attrs(params)

    case Ativos.create_asset(attrs) do
      {:ok, a} ->
        conn
        |> put_status(:created)
        |> json(%{data: DomainJSON.asset(a)})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: ApiJSON.changeset_errors(changeset)})
    end
  end

  defp asset_attrs(params) do
    p = params["asset"] || params["data"] || %{}

    %{ticker: p["ticker"] || p[:ticker], kind: normalize_kind(p["kind"] || p[:kind])}
    |> Enum.reject(fn {_, v} -> is_nil(v) end)
    |> Map.new()
  end

  defp normalize_kind(nil), do: nil

  defp normalize_kind(k) when is_binary(k) do
    k |> String.trim() |> String.downcase()
  end

  defp normalize_kind(k) when is_atom(k), do: Atom.to_string(k)
end
