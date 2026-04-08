defmodule DiagramaSavanaWeb.API.V1.SimulacaoAporteController do
  @moduledoc """
  Simulação e aplicação do motor de aporte/rebalanceamento (`DiagramaSavana.AporteMotor` +
  `DiagramaSavana.Aportes.Simulacao`).

  Corpo JSON: `simulacao_aporte.amount` (ou `data.amount` / `amount`). Resposta: ver
  `DiagramaSavanaWeb.API.V1.DomainJSON.simulacao_result/1`.
  """
  use DiagramaSavanaWeb, :api

  import Guardian.Plug, only: [current_resource: 1]

  alias DiagramaSavana.Carteiras
  alias DiagramaSavanaWeb.API.V1.DomainJSON
  alias DiagramaSavanaWeb.ApiJSON

  def create(conn, %{"portfolio_id" => portfolio_id} = params) do
    user = current_resource(conn)
    amount = parse_amount_field(params)

    with {:ok, portfolio} <- Carteiras.get_portfolio(user, portfolio_id),
         {:ok, sim} <- Carteiras.simulate_aporte(portfolio, amount) do
      json(conn, %{data: DomainJSON.simulacao_result(sim)})
    else
      {:error, :not_found} ->
        not_found(conn)

      {:error, :invalid_amount} ->
        unprocessable(conn, "Informe um valor numérico válido para o aporte.")

      {:error, :negative_amount} ->
        unprocessable(conn, "O valor do aporte deve ser maior que zero.")
    end
  end

  def aplicar(conn, %{"portfolio_id" => portfolio_id} = params) do
    user = current_resource(conn)
    amount = parse_amount_field(params)

    case Carteiras.apply_aporte_simulation(user, portfolio_id, amount) do
      {:ok, %{simulation: sim, aporte: aporte}} ->
        json(conn, %{
          data: %{
            simulacao: DomainJSON.simulacao_result(sim),
            aporte: DomainJSON.aporte(aporte)
          }
        })

      {:error, :not_found} ->
        not_found(conn)

      {:error, :invalid_amount} ->
        unprocessable(conn, "Informe um valor numérico válido para o aporte.")

      {:error, :negative_amount} ->
        unprocessable(conn, "O valor do aporte deve ser maior que zero.")

      {:error, {:aporte, %Ecto.Changeset{} = cs}} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: ApiJSON.changeset_errors(cs)})

      {:error, {:holding, %Ecto.Changeset{} = cs}} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: ApiJSON.changeset_errors(cs)})

      {:error, :holding_not_found} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          error: %{
            code: "posicao_invalida",
            message: "Uma posição da simulação não foi encontrada. Recalcule e tente novamente."
          }
        })
    end
  end

  defp parse_amount_field(params) do
    p = params["simulacao_aporte"] || params["data"] || %{}
    p["amount"] || p[:amount] || params["amount"] || ""
  end

  defp not_found(conn) do
    conn
    |> put_status(:not_found)
    |> json(%{error: %{code: "nao_encontrado", message: "Recurso não encontrado."}})
  end

  defp unprocessable(conn, message) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{error: %{code: "entrada_invalida", message: message}})
  end
end
