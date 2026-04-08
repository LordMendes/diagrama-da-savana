defmodule DiagramaSavana.Carteiras.PortfolioTest do
  use DiagramaSavana.DataCase, async: true

  alias DiagramaSavana.Accounts
  alias DiagramaSavana.Carteiras.Portfolio

  setup do
    {:ok, user} =
      Accounts.register_user(%{
        "email" => "carteira@example.com",
        "password" => "senha_segura_8",
        "password_confirmation" => "senha_segura_8"
      })

    {:ok, user: user}
  end

  describe "create_changeset/2" do
    test "aceita nome padrão quando omitido", %{user: user} do
      cs =
        %Portfolio{}
        |> Portfolio.create_changeset(%{user_id: user.id})

      assert cs.valid?
      assert Ecto.Changeset.get_field(cs, :name) == "Principal"
    end

    test "rejeita nome duplicado para o mesmo usuário", %{user: user} do
      _ =
        %Portfolio{}
        |> Portfolio.create_changeset(%{user_id: user.id, name: "Extra"})
        |> DiagramaSavana.Repo.insert!()

      cs =
        %Portfolio{}
        |> Portfolio.create_changeset(%{user_id: user.id, name: "Extra"})

      assert {:error, _} = DiagramaSavana.Repo.insert(cs)
    end
  end
end
