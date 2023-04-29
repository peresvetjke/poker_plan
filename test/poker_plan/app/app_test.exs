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
    assert App.get_round_tasks(round) == []
    # task1 = insert_task(%{round_id: round.id, title: "Task#1"})
    {:ok, task1} = App.create_task(%{round_id: round.id, title: "Task#1"})
    assert App.get_round_tasks(round) == [task1]
    # round_info = App.get_round_info!(10)

    # assert round_info.round.tasks == [task1]
    assert task1.state == "idle"
    refute App.current_task_info(round.id)
    App.start_task(task1)
    [task1] = App.get_round_tasks(round)
    assert task1.state == "doing"
    assert App.current_task_info(round.id).task == task1
    App.add_user_to_round(round, user2)
    round_info = App.round_info(round.id)
    assert Enum.sort(round_info.users) == [user1, user2]
    assert App.current_task_users_status(round.id) == %{user1.id => false, user2.id => false}
    App.estimate_task(user1, task1, 1)
    assert App.current_task_users_status(round.id) == %{user1.id => true, user2.id => false}
    refute App.current_task_estimates(round.id)
    App.estimate_task(user2, task1, 3)
    assert App.current_task_users_status(round.id) == %{user1.id => true, user2.id => true}
    [task1] = App.get_round_tasks(round)
    assert task1.state == "finished"
    IO.inspect("last test")
    assert App.current_task_estimates(round.id) == %{user1.id => 1, user2.id => 3}
  end
end
