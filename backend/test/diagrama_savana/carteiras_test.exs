defmodule DiagramaSavana.CarteirasTest do
  use DiagramaSavana.DataCase, async: true

  alias DiagramaSavana.Accounts
  alias DiagramaSavana.Ativos
  alias DiagramaSavana.Carteiras
  alias DiagramaSavana.Repo

  @password "senha_segura_8"

  setup do
    {:ok, user} =
      Accounts.register_user(%{
        "email" => "dominio@example.com",
        "password" => @password,
        "password_confirmation" => @password
      })

    {:ok, user: user}
  end

  test "ensure_default_portfolio/1 é idempotente", %{user: user} do
    assert {:ok, p1} = Carteiras.ensure_default_portfolio(user)
    assert {:ok, p2} = Carteiras.ensure_default_portfolio(user)
    assert p1.id == p2.id
    assert p1.name == "Principal"
  end

  test "create_holding/2 com quantidade e preço médio", %{user: user} do
    {:ok, portfolio} = Carteiras.ensure_default_portfolio(user)
    ticker = "TST#{System.unique_integer([:positive])}"
    {:ok, asset} = Ativos.create_asset(%{ticker: ticker, kind: :acao})

    assert {:ok, holding} =
             Carteiras.create_holding(portfolio, %{
               asset_id: asset.id,
               quantity: Decimal.new("10"),
               average_price: Decimal.new("35.50")
             })

    assert holding.portfolio_id == portfolio.id
    assert Decimal.equal?(holding.quantity, Decimal.new("10"))
  end

  test "não permite excluir carteira Principal", %{user: user} do
    {:ok, p} = Carteiras.ensure_default_portfolio(user)
    assert {:error, :default_readonly} = Carteiras.delete_portfolio(p)
  end

  test "permite excluir carteira extra", %{user: user} do
    {:ok, extra} = Carteiras.create_portfolio(user, %{name: "Extra"})
    assert {:ok, _} = Carteiras.delete_portfolio(extra)
    assert is_nil(Repo.get(DiagramaSavana.Carteiras.Portfolio, extra.id))
  end
end
