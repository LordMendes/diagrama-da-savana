defmodule DiagramaSavana.Brapi.Cache do
  @moduledoc """
  Simple ETS-backed cache for brapi responses with TTL.

  Default TTL comes from `:brapi_cache` (`default_ttl_seconds`) or `BRAPI_CACHE_TTL_SECONDS`.

  **TODO:** Replace with Cachex, Redis, or Nebulex when caching needs grow (invalidation,
  memory bounds, cluster-wide keys).
  """

  @table :diagrama_savana_brapi_cache

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

  defp default_ttl_seconds do
    Application.get_env(:diagrama_savana, :brapi_cache, [])
    |> Keyword.get(:default_ttl_seconds, 60)
  end
end
