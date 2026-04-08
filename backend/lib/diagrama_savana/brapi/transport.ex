defmodule DiagramaSavana.Brapi.Transport do
  @moduledoc false

  @callback get(String.t(), keyword()) ::
              {:ok, map()} | {:error, :rate_limited | :http_error | :invalid_json | term()}
end
