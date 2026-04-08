defmodule DiagramaSavana.Brapi.RateLimiter do
  @moduledoc """
  In-memory rate limiter for outbound **brapi.dev** HTTP calls.

  Uses one ETS table keyed by minute bucket. Tune via application env
  `:brapi_rate_limit` (`max_requests_per_minute`) or env `BRAPI_RATE_LIMIT_PER_MINUTE`.

  For production at scale, consider a shared limiter (Redis, etc.).
  """

  @table :diagrama_savana_brapi_rate_limiter

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

  @doc """
  Returns `:ok` if a request is allowed, or `{:error, :rate_limited}` if the
  per-minute budget is exhausted for the current bucket.
  """
  @spec acquire(atom() | String.t()) :: :ok | {:error, :rate_limited}
  def acquire(scope \\ :default) do
    ensure_table()

    limit = max_requests_per_minute()
    bucket = div(:erlang.system_time(:second), 60)
    key = {scope, bucket}

    case :ets.lookup(@table, key) do
      [] ->
        :ets.insert(@table, {key, 1})
        :ok

      [{^key, count}] when count < limit ->
        :ets.insert(@table, {key, count + 1})
        :ok

      [{^key, _count}] ->
        {:error, :rate_limited}
    end
  end

  defp max_requests_per_minute do
    Application.get_env(:diagrama_savana, :brapi_rate_limit, [])
    |> Keyword.get(:max_requests_per_minute, 60)
  end
end
