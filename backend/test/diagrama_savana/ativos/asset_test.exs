defmodule DiagramaSavana.Ativos.AssetTest do
  use DiagramaSavana.DataCase, async: true

  alias DiagramaSavana.Ativos.Asset

  describe "changeset/2" do
    test "normaliza ticker para maiúsculas" do
      cs =
        %Asset{}
        |> Asset.changeset(%{ticker: " petr4 ", kind: :acao})

      assert cs.valid?
      assert Ecto.Changeset.get_change(cs, :ticker) == "PETR4"
    end

    test "rejeita kind inválido" do
      cs = %Asset{} |> Asset.changeset(%{ticker: "X", kind: :invalid_kind})
      refute cs.valid?
    end
  end
end
