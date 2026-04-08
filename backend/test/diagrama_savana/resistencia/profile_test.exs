defmodule DiagramaSavana.Resistencia.ProfileTest do
  use DiagramaSavana.DataCase, async: true

  alias DiagramaSavana.Resistencia.Profile

  describe "changeset/2" do
    test "permite computed_score nulo" do
      cs =
        %Profile{}
        |> Profile.changeset(%{
          user_id: Ecto.UUID.generate(),
          asset_id: Ecto.UUID.generate(),
          computed_score: nil
        })

      assert cs.valid?
    end

    test "valida faixa quando presente" do
      cs =
        %Profile{}
        |> Profile.changeset(%{
          user_id: Ecto.UUID.generate(),
          asset_id: Ecto.UUID.generate(),
          computed_score: 11
        })

      refute cs.valid?
    end
  end
end
