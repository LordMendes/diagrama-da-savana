defmodule DiagramaSavana.Brapi.CryptoFallbackTest do
  use ExUnit.Case, async: true

  describe "matching/1" do
    test "finds BTC for full symbol" do
      assert "BTC" in DiagramaSavana.Brapi.CryptoFallback.matching("BTC")
    end

    test "prefix and substring" do
      hits = DiagramaSavana.Brapi.CryptoFallback.matching("BT")
      assert "BTC" in hits
      assert "ETH" in DiagramaSavana.Brapi.CryptoFallback.matching("ETH")
    end

    test "short query returns empty" do
      assert DiagramaSavana.Brapi.CryptoFallback.matching("B") == []
      assert DiagramaSavana.Brapi.CryptoFallback.matching("  ") == []
    end
  end

  describe "crypto_symbol?/1" do
    test "lista estática" do
      assert DiagramaSavana.Brapi.CryptoFallback.crypto_symbol?("BTC")
      assert DiagramaSavana.Brapi.CryptoFallback.crypto_symbol?("  eth  ")
      refute DiagramaSavana.Brapi.CryptoFallback.crypto_symbol?("PETR4")
      refute DiagramaSavana.Brapi.CryptoFallback.crypto_symbol?("")
    end
  end
end
