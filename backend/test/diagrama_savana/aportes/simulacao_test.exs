defmodule DiagramaSavana.Aportes.SimulacaoTest do
  use DiagramaSavana.DataCase, async: false

  alias DiagramaSavana.Accounts
  alias DiagramaSavana.Aportes.Simulacao
  alias DiagramaSavana.Aportes.SimulacaoCache
  alias DiagramaSavana.Carteiras

  @password "senha_segura_8"

  setup do
    :ok = SimulacaoCache.ensure_table()
    :ets.delete_all_objects(:diagrama_savana_simulacao_aporte_cache)

    {:ok, user} =
      Accounts.register_user(%{
        "email" => "sim.cache.#{System.unique_integer([:positive])}@example.com",
        "password" => @password,
        "password_confirmation" => @password
      })

    {:ok, portfolio} = Carteiras.ensure_default_portfolio(user)
    {:ok, user: user, portfolio: portfolio}
  end

  test "mesmo aporte e carteira reutilizam uma entrada de cache", %{portfolio: portfolio} do
    assert SimulacaoCache.size() == 0
    assert {:ok, a} = Simulacao.run(portfolio, "1500.00")
    assert SimulacaoCache.size() == 1
    assert {:ok, b} = Simulacao.run(portfolio, "1500.00")
    assert SimulacaoCache.size() == 1
    assert a == b
  end

  test "valores normalizados iguais compartilham cache", %{portfolio: portfolio} do
    assert {:ok, a} = Simulacao.run(portfolio, "100")
    assert {:ok, b} = Simulacao.run(portfolio, "100.00")
    assert a == b
    assert SimulacaoCache.size() == 1
  end

  test "cache: false não grava no cache", %{portfolio: portfolio} do
    assert {:ok, _} = Simulacao.run(portfolio, "200", cache: false)
    assert SimulacaoCache.size() == 0
  end

  test "montantes diferentes geram entradas distintas", %{portfolio: portfolio} do
    assert {:ok, _} = Simulacao.run(portfolio, "100")
    assert {:ok, _} = Simulacao.run(portfolio, "200")
    assert SimulacaoCache.size() == 2
  end
end
