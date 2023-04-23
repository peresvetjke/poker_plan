defmodule PokerPlan.Data.TaskTest do
  use PokerPlan.DataCase, async: true

  @valid_attrs %{title: "A Task"}
  @invalid_attrs %{}

  setup do
    round = insert_round()
    {:ok, round: round}
  end

  test "changeset with valid attributes", %{round: round} do
    attrs = Map.put(@valid_attrs, :round, round)
    changeset = Task.changeset(%Task{}, attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Task.changeset(%Task{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "changeset does not accept long usernames" do
    attrs = Map.put(@valid_attrs, :title, String.duplicate("a", 30))
    changeset = Task.changeset(%Task{}, attrs)
    assert [title: {"should be at most %{count} character(s)", _}] = changeset.errors
  end
end
