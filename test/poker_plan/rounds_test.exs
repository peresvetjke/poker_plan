defmodule PokerPlan.RoundsTest do
  use PokerPlan.DataCase

  alias PokerPlan.Rounds

  describe "rounds" do
    alias PokerPlan.Rounds.Round

    import PokerPlan.RoundsFixtures

    @invalid_attrs %{title: nil}

    test "list_rounds/0 returns all rounds" do
      round = round_fixture()
      assert Rounds.list_rounds() == [round]
    end

    test "get_round!/1 returns the round with given id" do
      round = round_fixture()
      assert Rounds.get_round!(round.id) == round
    end

    test "create_round/1 with valid data creates a round" do
      valid_attrs = %{title: "some title"}

      assert {:ok, %Round{} = round} = Rounds.create_round(valid_attrs)
      assert round.title == "some title"
    end

    test "create_round/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Rounds.create_round(@invalid_attrs)
    end

    test "update_round/2 with valid data updates the round" do
      round = round_fixture()
      update_attrs = %{title: "some updated title"}

      assert {:ok, %Round{} = round} = Rounds.update_round(round, update_attrs)
      assert round.title == "some updated title"
    end

    test "update_round/2 with invalid data returns error changeset" do
      round = round_fixture()
      assert {:error, %Ecto.Changeset{}} = Rounds.update_round(round, @invalid_attrs)
      assert round == Rounds.get_round!(round.id)
    end

    test "delete_round/1 deletes the round" do
      round = round_fixture()
      assert {:ok, %Round{}} = Rounds.delete_round(round)
      assert_raise Ecto.NoResultsError, fn -> Rounds.get_round!(round.id) end
    end

    test "change_round/1 returns a round changeset" do
      round = round_fixture()
      assert %Ecto.Changeset{} = Rounds.change_round(round)
    end
  end
end
