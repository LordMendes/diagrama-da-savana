defmodule DiagramaSavana.Brapi.ClientTest do
  use ExUnit.Case, async: false

  import Mox

  setup :verify_on_exit!

  setup do
    DiagramaSavana.Brapi.Cache.ensure_table()
    :ets.delete_all_objects(:diagrama_savana_brapi_cache)
    :ok
  end

  describe "search_tickers/1" do
    test "string vazia não chama HTTP" do
      assert {:ok, %{"indexes" => [], "stocks" => []}} ==
               DiagramaSavana.Brapi.Client.search_tickers("  ")
    end

    test "retorna dados do transport" do
      q = "uniq#{System.unique_integer([:positive])}"

      expect(DiagramaSavana.Brapi.TransportMock, :get, fn url, params ->
        assert Keyword.has_key?(params, :search)
        assert params[:search] == q
        assert url =~ "/available"
        refute url =~ "crypto"
        {:ok, %{"indexes" => ["^BVSP"], "stocks" => ["PETR4"]}}
      end)

      expect(DiagramaSavana.Brapi.TransportMock, :get, fn url, params ->
        assert url =~ "crypto/available"
        assert params[:search] == q
        {:ok, %{"coins" => ["BTC"]}}
      end)

      assert {:ok, %{"stocks" => ["PETR4", "BTC"]}} =
               DiagramaSavana.Brapi.Client.search_tickers(q)
    end

    test "usa cache na segunda chamada" do
      q = "cache#{System.unique_integer([:positive])}"

      expect(DiagramaSavana.Brapi.TransportMock, :get, fn url, _ ->
        refute url =~ "crypto"
        {:ok, %{"indexes" => [], "stocks" => ["X"]}}
      end)

      expect(DiagramaSavana.Brapi.TransportMock, :get, fn url, _ ->
        assert url =~ "crypto/available"
        {:ok, %{"coins" => []}}
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

    test "cripto usa /v2/crypto com currency BRL" do
      expect(DiagramaSavana.Brapi.TransportMock, :get, fn url, params ->
        assert url =~ "/v2/crypto"
        assert params[:coin] == "BTC"
        assert params[:currency] == "BRL"

        {:ok,
         %{
           "coins" => [
             %{"coin" => "BTC", "regularMarketPrice" => 364_824.12, "currency" => "BRL"}
           ]
         }}
      end)

      assert {:ok, %{"results" => [%{"symbol" => "BTC", "regularMarketPrice" => p}]}} =
               DiagramaSavana.Brapi.Client.fetch_quote("BTC")

      assert p == 364_824.12
    end
  end

  describe "fetch_quotes_many/2" do
    setup do
      prev = Application.get_env(:diagrama_savana, :brapi, [])

      Application.put_env(
        :diagrama_savana,
        :brapi,
        prev
        |> Keyword.put(:quote_batch_size, 2)
        |> Keyword.put(:quote_batch_http_enabled, true)
      )

      on_exit(fn -> Application.put_env(:diagrama_savana, :brapi, prev) end)
      :ok
    end

    test "uma requisição HTTP para vários tickers" do
      u1 = "U#{System.unique_integer([:positive])}"
      u2 = "U#{System.unique_integer([:positive])}"

      expect(DiagramaSavana.Brapi.TransportMock, :get, fn url, _params ->
        assert url =~ "/quote/#{u1},#{u2}"

        {:ok,
         %{
           "results" => [
             %{"symbol" => u1, "regularMarketPrice" => 10},
             %{"symbol" => u2, "regularMarketPrice" => 20}
           ]
         }}
      end)

      m = DiagramaSavana.Brapi.Client.fetch_quotes_many([u1, u2])

      assert {:ok, %{"results" => [%{"symbol" => ^u1}]}} = Map.fetch!(m, u1)
      assert {:ok, %{"results" => [%{"symbol" => ^u2}]}} = Map.fetch!(m, u2)
    end

    test "fallback para fetch_quote/2 quando o lote retorna erro HTTP" do
      u1 = "U#{System.unique_integer([:positive])}"
      u2 = "U#{System.unique_integer([:positive])}"

      expect(DiagramaSavana.Brapi.TransportMock, :get, fn url, _params ->
        assert url =~ "/quote/#{u1},#{u2}"
        {:error, :http_error}
      end)

      expect(DiagramaSavana.Brapi.TransportMock, :get, fn url, _params ->
        assert url =~ "/quote/#{u1}"
        refute url =~ "#{u1},"
        {:ok, %{"results" => [%{"symbol" => u1, "regularMarketPrice" => 1}]}}
      end)

      expect(DiagramaSavana.Brapi.TransportMock, :get, fn url, _params ->
        assert url =~ "/quote/#{u2}"
        {:ok, %{"results" => [%{"symbol" => u2, "regularMarketPrice" => 2}]}}
      end)

      m = DiagramaSavana.Brapi.Client.fetch_quotes_many([u1, u2])

      assert {:ok, %{"results" => [%{"symbol" => ^u1}]}} = Map.fetch!(m, u1)
      assert {:ok, %{"results" => [%{"symbol" => ^u2}]}} = Map.fetch!(m, u2)
    end

    test "lista vazia não chama HTTP" do
      assert %{} == DiagramaSavana.Brapi.Client.fetch_quotes_many([])
    end

    test "com lote HTTP desligado, não usa URL com vários tickers" do
      prev = Application.get_env(:diagrama_savana, :brapi, [])

      Application.put_env(
        :diagrama_savana,
        :brapi,
        prev
        |> Keyword.put(:quote_batch_size, 20)
        |> Keyword.put(:quote_batch_http_enabled, false)
      )

      on_exit(fn -> Application.put_env(:diagrama_savana, :brapi, prev) end)

      u1 = "U#{System.unique_integer([:positive])}"
      u2 = "U#{System.unique_integer([:positive])}"

      expect(DiagramaSavana.Brapi.TransportMock, :get, fn url, _params ->
        refute url =~ ","
        assert url =~ "/quote/#{u1}"
        {:ok, %{"results" => [%{"symbol" => u1, "regularMarketPrice" => 1}]}}
      end)

      expect(DiagramaSavana.Brapi.TransportMock, :get, fn url, _params ->
        refute url =~ ","
        assert url =~ "/quote/#{u2}"
        {:ok, %{"results" => [%{"symbol" => u2, "regularMarketPrice" => 2}]}}
      end)

      m = DiagramaSavana.Brapi.Client.fetch_quotes_many([u1, u2])

      assert {:ok, _} = Map.fetch!(m, u1)
      assert {:ok, _} = Map.fetch!(m, u2)
    end

    test "separa cripto de ativos B3 em requisições distintas" do
      eq = "U#{System.unique_integer([:positive])}"

      expect(DiagramaSavana.Brapi.TransportMock, :get, fn url, _params ->
        assert url =~ "/quote/#{eq}"
        refute url =~ "BTC"
        {:ok, %{"results" => [%{"symbol" => eq, "regularMarketPrice" => 1}]}}
      end)

      expect(DiagramaSavana.Brapi.TransportMock, :get, fn url, params ->
        assert url =~ "/v2/crypto"
        assert params[:coin] == "BTC"
        assert params[:currency] == "BRL"
        refute url =~ eq

        {:ok,
         %{
           "coins" => [
             %{"coin" => "BTC", "regularMarketPrice" => 364_000.0, "currency" => "BRL"}
           ]
         }}
      end)

      m = DiagramaSavana.Brapi.Client.fetch_quotes_many([eq, "BTC"])

      assert {:ok, %{"results" => [%{"symbol" => ^eq}]}} = Map.fetch!(m, eq)
      assert {:ok, %{"results" => [%{"symbol" => "BTC"}]}} = Map.fetch!(m, "BTC")
    end
  end
end
