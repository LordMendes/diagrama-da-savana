defmodule DiagramaSavana.Brapi.RateLimiterTest do
  use ExUnit.Case, async: false

  setup do
    prev = Application.get_env(:diagrama_savana, :brapi_rate_limit)

    Application.put_env(:diagrama_savana, :brapi_rate_limit, max_requests_per_minute: 2)

    scope = {:test_rate_limit, :erlang.unique_integer([:positive])}
    :ok = DiagramaSavana.Brapi.RateLimiter.ensure_table()

    on_exit(fn ->
      Application.put_env(:diagrama_savana, :brapi_rate_limit, prev)
    end)

    %{scope: scope}
  end

  test "allows up to configured requests per minute bucket then rate limits", %{scope: scope} do
    assert :ok == DiagramaSavana.Brapi.RateLimiter.acquire(scope)
    assert :ok == DiagramaSavana.Brapi.RateLimiter.acquire(scope)
    assert {:error, :rate_limited} == DiagramaSavana.Brapi.RateLimiter.acquire(scope)
  end
end
