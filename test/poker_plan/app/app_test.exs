defmodule PokerPlan.AppTest do
  use PokerPlan.DataCase, async: false

  alias PokerPlan.App

  test "base" do
    user1 = insert_user(%{email: "user1@example.com"})
    user2 = insert_user(%{email: "user2@example.com"})
    round = insert_round(%{title: "Round#1"})

    round_info = App.round_info(round.id)
    assert round_info.users == []
    App.add_user_to_round(round, user1)
    round_info = App.round_info(round.id)
    assert round_info.users == [user1]
    assert round_info.round.tasks == []
    assert App.round_tasks(round) == []
    {:ok, task1} = App.create_task(%{round_id: round.id, title: "Task#1"})
    assert App.round_tasks(round) == [task1]
    assert task1.state == "idle"
    refute App.current_task(round.id)
    App.start_task(task1)
    [task1] = App.round_tasks(round)
    assert task1.state == "doing"
    {:ok, task2} = App.create_task(%{round_id: round.id, title: "Task#2"})
    App.start_task(task2)
    task1_id = task1.id
    :timer.sleep(500)
    task1 = PokerPlan.Repo.get(PokerPlan.Data.Task, task1_id)
    assert task1.state == "idle"
    assert App.current_task(round.id).id == task2.id
    assert App.current_task(round.id).state == "doing"
    assert App.current_task_users_status(round.id) == %{user1.id => false}
    App.add_user_to_round(round, user2)
    round_info = App.round_info(round.id)
    assert Enum.sort(round_info.users) == [user1, user2]
    assert App.current_task_users_status(round.id) == %{user1.id => false, user2.id => false}
    App.estimate_task(user1, task2, 1)
    assert App.current_task_users_status(round.id) == %{user1.id => true, user2.id => false}
    App.remove_user_from_round(user1.id, round.id)
    round_info = App.round_info(round.id)
    assert Enum.sort(round_info.users) == [user2]
    assert App.current_task_users_status(round.id) == %{user2.id => false}
    App.estimate_task(user1, task2, 1)
    assert App.current_task_user_estimation_value(round, user1) == 1
    App.estimate_task(user1, task2, 1)
    assert App.current_task_users_status(round.id) == %{user1.id => false, user2.id => false}
    App.estimate_task(user1, task2, 1)
    App.estimate_task(user1, task2, 5)
    refute App.task_estimates(task2.id)
    assert App.current_task(round.id).id == task2.id
    App.estimate_task(user2, task2, 3)
    # assert App.current_task_users_status(round.id) == %{user1.id => true, user2.id => true}
    refute App.current_task(round.id)
    assert PokerPlan.Repo.get(PokerPlan.Data.Task, task2.id).state == "finished"

    # assert %{%{id: ^user1_id} => 1, %{id: ^user2_id} => 3} = App.task_estimates(task2.id)
    # IO.inspect("last test")

    assert App.task_estimates(task2.id) == %{user1.id => 5, user2.id => 3}

    # IO.inspect(Repo.all(PokerPlan.Data.Estimation))
    task2_id = task2.id
    estimations = Repo.all(from e in PokerPlan.Data.Estimation, where: e.task_id == ^task2_id)
    assert Enum.map(estimations, &Map.get(&1, :value)) |> length() == 2
  end
end
