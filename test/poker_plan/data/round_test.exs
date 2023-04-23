defmodule PokerPlan.Data.RoundTest do
  use PokerPlan.DataCase, async: true

  @valid_attrs %{title: "A Round"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Round.changeset(%Round{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Round.changeset(%Round{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "changeset does not accept long usernames" do
    attrs = Map.put(@valid_attrs, :title, String.duplicate("a", 30))
    changeset = Round.changeset(%Round{}, attrs)

    assert [title: {"should be at most %{count} character(s)", _}] = changeset.errors
  end
end
