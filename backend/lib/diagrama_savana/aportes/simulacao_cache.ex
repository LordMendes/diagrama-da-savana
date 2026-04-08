defmodule DiagramaSavana.Aportes.SimulacaoCache do
  @moduledoc """
  ETS cache for `DiagramaSavana.Aportes.Simulacao` results (TTL, default 30 minutes).

  Keys are built in `Simulacao` (portfolio, amount, inputs version). **Apply** flows
  bypass the cache via `Simulacao.run(..., cache: false)`.
  """

  @table :diagrama_savana_simulacao_aporte_cache

  @type key :: term()

  @spec ensure_table() :: :ok
  def ensure_table do
    case :ets.whereis(@table) do
      :undefined ->
        :ets.new(@table, [:named_table, :public, :set])
        :ok

      _ ->
        :ok
    end
  end

  @doc "Returns `{:ok, value}` or `:miss`."
  @spec get(key()) :: {:ok, term()} | :miss
  def get(key) do
    ensure_table()
    now = :erlang.system_time(:second)

    case :ets.lookup(@table, key) do
      [] ->
        :miss

      [{^key, {expires_at, value}}] when expires_at > now ->
        {:ok, value}

      [{^key, _expired}] ->
        :ets.delete(@table, key)
        :miss
    end
  end

  @doc "Stores `value` with TTL in seconds."
  @spec put(key(), term(), keyword()) :: :ok
  def put(key, value, opts \\ []) do
    ensure_table()
    ttl = Keyword.get(opts, :ttl, default_ttl_seconds())
    expires_at = :erlang.system_time(:second) + ttl
    :ets.insert(@table, {key, {expires_at, value}})
    :ok
  end

  @doc """
  Number of entries (for tests / diagnostics). Not O(1) on all ETS implementations;
  fine for small tables.
  """
  @spec size() :: non_neg_integer()
  def size do
    ensure_table()
    :ets.info(@table, :size)
  end

  defp default_ttl_seconds do
    Application.get_env(:diagrama_savana, :simulacao_aporte_cache, [])
    |> Keyword.get(:default_ttl_seconds, 1800)
  end
end
