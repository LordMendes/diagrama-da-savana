defmodule DiagramaSavana.Brapi.ClientTest do
  use ExUnit.Case, async: false

  import Mox

  setup :verify_on_exit!

  setup do
    DiagramaSavana.Brapi.Cache.ensure_table()
    :ok
  end

  describe "search_tickers/1" do
    test "string vazia não chama HTTP" do
      assert {:ok, %{"indexes" => [], "stocks" => []}} ==
               DiagramaSavana.Brapi.Client.search_tickers("  ")
    end

    test "retorna dados do transport" do
      q = "uniq#{System.unique_integer([:positive])}"

      expect(DiagramaSavana.Brapi.TransportMock, :get, fn _url, params ->
        assert Keyword.has_key?(params, :search)
        assert params[:search] == q
        {:ok, %{"indexes" => ["^BVSP"], "stocks" => ["PETR4"]}}
      end)

      assert {:ok, %{"stocks" => ["PETR4"]}} =
               DiagramaSavana.Brapi.Client.search_tickers(q)
    end

    test "usa cache na segunda chamada" do
      q = "cache#{System.unique_integer([:positive])}"

      expect(DiagramaSavana.Brapi.TransportMock, :get, fn _, _ ->
        {:ok, %{"indexes" => [], "stocks" => ["X"]}}
      end)

      assert {:ok, _} = DiagramaSavana.Brapi.Client.search_tickers(q)
      assert {:ok, %{"stocks" => ["X"]}} = DiagramaSavana.Brapi.Client.search_tickers(q)
    end
  end

  describe "fetch_quote/2" do
    test "cotação simples" do
      t = "U#{System.unique_integer([:positive])}"

      expect(DiagramaSavana.Brapi.TransportMock, :get, fn url, _params ->
        assert url =~ "/quote/#{t}"
        {:ok, %{"results" => [%{"symbol" => t}]}}
      end)

      assert {:ok, %{"results" => _}} = DiagramaSavana.Brapi.Client.fetch_quote(t)
    end

    test "passa range e interval ao transport" do
      t = "U#{System.unique_integer([:positive])}"

      expect(DiagramaSavana.Brapi.TransportMock, :get, fn url, params ->
        assert url =~ "/quote/#{t}"
        assert params[:range] == "1mo"
        assert params[:interval] == "1d"
        {:ok, %{"results" => []}}
      end)

      assert {:ok, _} =
               DiagramaSavana.Brapi.Client.fetch_quote(t, range: "1mo", interval: "1d")
    end

    test "propaga rate limit do transport" do
      t = "U#{System.unique_integer([:positive])}"

      expect(DiagramaSavana.Brapi.TransportMock, :get, fn _, _ ->
        {:error, :rate_limited}
      end)

      assert {:error, :rate_limited} = DiagramaSavana.Brapi.Client.fetch_quote(t)
    end
  end
end
