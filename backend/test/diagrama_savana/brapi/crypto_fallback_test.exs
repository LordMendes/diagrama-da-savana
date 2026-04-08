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
end
