defmodule PokerPlan.Data.EstimationTest do
  use PokerPlan.DataCase, async: true

  @valid_attrs %{value: 5}
  @invalid_attrs %{}

  setup do
    user = insert_user()
    task = insert_task()
    {:ok, task: task, user: user}
  end

  test "changeset with valid attributes", %{task: task, user: user} do
    attrs =
      @valid_attrs
      |> Map.put(:task, task)
      |> Map.put(:user, user)

    changeset = Estimation.changeset(%Estimation{}, attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Estimation.changeset(%Estimation{}, @invalid_attrs)
    refute changeset.valid?
  end
end
