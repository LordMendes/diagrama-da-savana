defmodule DiagramaSavanaWeb.API.V1.ResistanceProfileController do
  use DiagramaSavanaWeb, :api

  import Guardian.Plug, only: [current_resource: 1]

  alias DiagramaSavana.Ativos
  alias DiagramaSavana.Repo
  alias DiagramaSavana.Resistencia
  alias DiagramaSavanaWeb.API.V1.DomainJSON
  alias DiagramaSavanaWeb.ApiJSON

  def index(conn, _params) do
    user = current_resource(conn)
    rows = Resistencia.list_profiles(user)
    json(conn, %{data: Enum.map(rows, &DomainJSON.resistance_profile/1)})
  end

  def show(conn, %{"asset_id" => asset_id}) do
    user = current_resource(conn)

    case Ativos.get_asset(asset_id) do
      nil ->
        not_found(conn)

      asset ->
        case Resistencia.get_profile(user, asset.id) do
          {:ok, p} ->
            json(conn, %{data: DomainJSON.resistance_profile(p)})

          {:error, :not_found} ->
            conn
            |> put_status(:not_found)
            |> json(%{
              error: %{code: "nao_encontrado", message: "Nota de resistência não encontrada."}
            })
        end
    end
  end

  def upsert(conn, %{"asset_id" => asset_id} = params) do
    user = current_resource(conn)
    attrs = profile_attrs(params)

    case Ativos.get_asset(asset_id) do
      nil ->
        not_found(conn)

      asset ->
        case Resistencia.upsert_profile(user, asset, attrs) do
          {:ok, p} ->
            p = Repo.preload(p, :asset)
            json(conn, %{data: DomainJSON.resistance_profile(p)})

          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{errors: ApiJSON.changeset_errors(changeset)})
        end
    end
  end

  def delete(conn, %{"asset_id" => asset_id}) do
    user = current_resource(conn)

    case Ativos.get_asset(asset_id) do
      nil ->
        not_found(conn)

      asset ->
        case Resistencia.delete_profile(user, asset) do
          {:ok, _} ->
            send_resp(conn, :no_content, "")

          {:error, :not_found} ->
            conn
            |> put_status(:not_found)
            |> json(%{
              error: %{code: "nao_encontrado", message: "Nota de resistência não encontrada."}
            })
        end
    end
  end

  defp profile_attrs(params) do
    p = params["resistance_profile"] || params["data"] || %{}

    criteria =
      cond do
        is_map(p["criteria"]) -> p["criteria"]
        is_map(p["criteria_stub"]) -> p["criteria_stub"]
        is_map(p[:criteria]) -> p[:criteria]
        is_map(p[:criteria_stub]) -> p[:criteria_stub]
        true -> %{}
      end

    %{"criteria" => criteria}
  end

  defp not_found(conn) do
    conn
    |> put_status(:not_found)
    |> json(%{error: %{code: "nao_encontrado", message: "Ativo não encontrado."}})
  end
end
