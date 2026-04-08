defmodule DiagramaSavana.Resistencia do
  @moduledoc """
  **Nota de Resistência** por usuário e ativo: checklist (-1/0/+1 por critério), nota final **-5 a +10**.

  Ativos com nota **≤ 0** não entram na alocação micro (calculadora de aporte — step 8).
  """

  import Ecto.Query

  alias DiagramaSavana.Accounts.User
  alias DiagramaSavana.Ativos.Asset
  alias DiagramaSavana.Repo
  alias DiagramaSavana.Resistencia.{Criteria, Profile, Scoring}

  def list_profiles(%User{id: user_id}) do
    from(p in Profile,
      where: p.user_id == ^user_id,
      preload: [:asset],
      order_by: [asc: p.inserted_at]
    )
    |> Repo.all()
  end

  def get_profile(%User{id: user_id}, asset_id) do
    case Repo.get_by(Profile, user_id: user_id, asset_id: asset_id) do
      %Profile{} = p -> {:ok, Repo.preload(p, :asset)}
      nil -> {:error, :not_found}
    end
  end

  @doc """
  Cria ou atualiza o perfil usando **apenas** o mapa `criteria` (critério → -1, 0 ou 1).
  O `computed_score` é sempre recalculado no servidor.
  """
  def upsert_profile(%User{id: user_id}, %Asset{} = asset, attrs) when is_map(attrs) do
    criteria = extract_criteria_map(attrs)

    case Scoring.build_for_upsert(asset, criteria) do
      {:ok, built} ->
        upsert_profile_row(user_id, asset.id, built)

      {:error, :unsupported_kind} ->
        {:error, unsupported_kind_changeset()}

      {:error, {:unknown_criteria, keys}} ->
        {:error, criteria_error_changeset("Critérios desconhecidos: #{Enum.join(keys, ", ")}")}

      {:error, {:invalid_values, ids}} ->
        {:error,
         criteria_error_changeset(
           "Cada critério deve ser -1, 0 ou 1. Verifique: #{Enum.join(ids, ", ")}"
         )}
    end
  end

  defp upsert_profile_row(user_id, asset_id, %{criteria_stub: stub, computed_score: score}) do
    attrs = %{criteria_stub: stub, computed_score: score}

    case Repo.get_by(Profile, user_id: user_id, asset_id: asset_id) do
      nil ->
        %Profile{}
        |> Profile.changeset(
          attrs
          |> Map.put(:user_id, user_id)
          |> Map.put(:asset_id, asset_id)
        )
        |> Repo.insert()

      %Profile{} = existing ->
        existing
        |> Profile.changeset(attrs)
        |> Repo.update()
    end
  end

  defp extract_criteria_map(attrs) do
    cond do
      is_map(attrs[:criteria]) -> attrs[:criteria]
      is_map(attrs["criteria"]) -> attrs["criteria"]
      is_map(attrs[:criteria_stub]) -> attrs[:criteria_stub]
      is_map(attrs["criteria_stub"]) -> attrs["criteria_stub"]
      true -> %{}
    end
  end

  defp unsupported_kind_changeset do
    %Profile{}
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.add_error(
      :base,
      "Nota de resistência está disponível para ações, ETFs, FIIs e cripto."
    )
  end

  defp criteria_error_changeset(msg) do
    %Profile{}
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.add_error(:criteria_stub, msg)
  end

  def delete_profile(%User{} = user, %Asset{} = asset) do
    case Repo.get_by(Profile, user_id: user.id, asset_id: asset.id) do
      nil -> {:error, :not_found}
      %Profile{} = p -> Repo.delete(p)
    end
  end

  @doc """
  `true` se a nota permite participar da alocação por peso (nota > 0).
  """
  def eligible_for_allocation?(%Profile{computed_score: s}) when is_integer(s), do: s > 0
  def eligible_for_allocation?(_), do: false

  @doc """
  Retorna ids de ativos com nota > 0 para o usuário (base da camada micro no step 8).
  """
  def eligible_asset_ids_for_user(user_id) when is_binary(user_id) do
    from(p in Profile,
      where: p.user_id == ^user_id and p.computed_score > 0,
      select: p.asset_id
    )
    |> Repo.all()
  end

  @doc """
  Perfis de resistência do usuário para um conjunto de ativos (ex.: posições da carteira).
  """
  def list_profiles_for_assets(%User{id: user_id}, asset_ids) when is_list(asset_ids) do
    case asset_ids do
      [] ->
        []

      ids ->
        from(p in Profile,
          where: p.user_id == ^user_id and p.asset_id in ^ids,
          preload: [:asset]
        )
        |> Repo.all()
    end
  end

  def criteria_group_for_asset(%Asset{} = asset), do: Criteria.group_for_asset_kind(asset.kind)

  def definitions_for_asset(%Asset{} = asset) do
    case Criteria.group_for_asset_kind(asset.kind) do
      nil -> nil
      group -> Criteria.definitions(group)
    end
  end
end
