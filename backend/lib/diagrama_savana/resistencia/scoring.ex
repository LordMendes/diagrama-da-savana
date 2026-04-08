defmodule DiagramaSavana.Resistencia.Scoring do
  @moduledoc """
  Cálculo da Nota de Resistência: soma dos critérios (-1 / 0 / +1) com limite **-5 a +10**.

  Valores fora da faixa após a soma são **ajustados** (clamp), não truncados por critério.
  """

  alias DiagramaSavana.Ativos.Asset
  alias DiagramaSavana.Resistencia.Criteria

  @min_score -5
  @max_score 10

  def score_range, do: {@min_score, @max_score}

  @doc """
  Soma com limite aplicado (mesmo resultado persistido em `computed_score`).
  """
  def clamp(raw) when is_integer(raw) do
    raw |> max(@min_score) |> min(@max_score)
  end

  @doc """
  A partir do mapa de critérios (ids → -1 | 0 | 1), calcula soma bruta e nota final.
  """
  def compute_raw_and_final(group, criteria_int_map)
      when group in [:acao, :fii, :cripto] and is_map(criteria_int_map) do
    raw =
      criteria_int_map
      |> Map.values()
      |> Enum.sum()

    {raw, clamp(raw)}
  end

  @doc """
  Prepara `criteria_stub` + `computed_score` para persistência a partir do input da API.

  - Chaves desconhecidas ou valores inválidos geram erro.
  - Critérios omitidos são tratados como **0**.
  """
  def build_for_upsert(%Asset{} = asset, raw_criteria) when is_map(raw_criteria) do
    case Criteria.group_for_asset_kind(asset.kind) do
      nil -> {:error, :unsupported_kind}
      group -> normalize_and_build(group, raw_criteria)
    end
  end

  defp normalize_and_build(group, raw) do
    allowed = Criteria.ids(group)
    raw_string_keys = stringify_keys(raw)

    case forbidden_keys(raw_string_keys, allowed) do
      [] ->
        case build_int_map(allowed, raw_string_keys) do
          {:ok, int_map} ->
            {_raw, final} = compute_raw_and_final(group, int_map)
            {:ok, %{criteria_stub: int_map, computed_score: final}}

          {:error, _} = e ->
            e
        end

      keys ->
        {:error, {:unknown_criteria, keys}}
    end
  end

  defp forbidden_keys(map, allowed) do
    Map.keys(map) -- allowed
  end

  defp build_int_map(allowed_ids, raw_map) do
    Enum.reduce_while(allowed_ids, {:ok, %{}}, fn id, {:ok, acc} ->
      case parse_value(Map.get(raw_map, id, 0)) do
        {:ok, n} -> {:cont, {:ok, Map.put(acc, id, n)}}
        {:error, _} -> {:halt, {:error, {:invalid_values, [id]}}}
      end
    end)
  end

  defp parse_value(v) do
    case coerce_int(v) do
      {:ok, n} when n in [-1, 0, 1] -> {:ok, n}
      {:ok, _} -> {:error, :out_of_range}
      :error -> {:error, :invalid}
    end
  end

  defp coerce_int(v) when v in [-1, 0, 1], do: {:ok, v}
  defp coerce_int(v) when is_integer(v), do: {:ok, v}

  defp coerce_int(v) when is_binary(v) do
    case Integer.parse(String.trim(v)) do
      {n, ""} -> {:ok, n}
      _ -> :error
    end
  end

  defp coerce_int(v) when is_float(v) and v == trunc(v), do: {:ok, trunc(v)}
  defp coerce_int(_), do: :error

  defp stringify_keys(map) when is_map(map) do
    Map.new(map, fn
      {k, v} when is_atom(k) -> {Atom.to_string(k), v}
      {k, v} when is_binary(k) -> {k, v}
    end)
  end
end
