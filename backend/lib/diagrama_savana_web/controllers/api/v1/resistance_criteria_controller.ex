defmodule DiagramaSavanaWeb.API.V1.ResistanceCriteriaController do
  use DiagramaSavanaWeb, :api

  alias DiagramaSavana.Resistencia.Criteria

  def index(conn, params) do
    kind = params["kind"] || "acao"

    case Criteria.group_for_query_param(kind) do
      {:ok, group} ->
        json(conn, %{data: Criteria.definitions(group)})

      {:error, _} ->
        conn
        |> put_status(:bad_request)
        |> json(%{
          error: %{
            code: "parametro_invalido",
            message: "Informe kind=acao ou kind=fii (ETFs usam o mesmo checklist de ações)."
          }
        })
    end
  end
end
