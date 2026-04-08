defmodule DiagramaSavana.Brapi.CryptoFallback do
  @moduledoc false

  # When GET /v2/crypto/available fails (403/plan) or returns no rows, offer a
  # static subset so autocomplete still works for common symbols (e.g. BTC).

  @tickers ~w(
    BTC ETH USDT USDC BNB SOL XRP ADA DOGE TRX AVAX DOT MATIC POL LINK SHIB LTC BCH UNI ATOM NEAR
    OKB XLM TON CRO FIL HBAR APT OP INJ ARB VET GRT IMX FTM SAND AAVE THETA SNX CRV EOS MKR XTZ CHZ
    WBTC DAI BUSD LEO FET SUSHI GALA RUNE PEPE WIF BONK JUP PYTH TIA SEI STRK
  )

  @spec matching(String.t()) :: [String.t()]
  def matching(query) when is_binary(query) do
    q = query |> String.trim() |> String.upcase()

    if String.length(q) < 2 do
      []
    else
      @tickers
      |> Enum.filter(fn t ->
        String.starts_with?(t, q) or String.contains?(t, q)
      end)
      |> Enum.sort()
    end
  end
end
