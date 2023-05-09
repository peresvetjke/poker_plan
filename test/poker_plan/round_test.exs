defmodule PokerPlan.RoundTest do
  use PokerPlan.DataCase, async: false

  import Ecto.Query, only: [from: 2]

  alias PokerPlan.{Repo, Round, Task}

  test "base" do
    user1 = insert_user(%{email: "user1@example.com"})
    user2 = insert_user(%{email: "user2@example.com"})
    round = insert_round(%{title: "Round#1"})
    task1 = insert_task(%{title: "Task#1", round_id: round.id})

    task1 =
      Repo.get(PokerPlan.Data.Task, task1.id)
      |> Repo.preload(:estimations)

    {:ok, task1_pid} = Task.start_link(task1)
    round_id = round.id

    round =
      PokerPlan.Data.Round
      |> PokerPlan.Repo.get(round.id)
      |> PokerPlan.Repo.preload(:tasks)

    {:ok, pid} = Round.start_link(round)
    assert Round.get(pid).users == []
    assert Round.get(pid).tasks |> Enum.map(& &1.task.id) == [task1.id]
    Round.add_user(pid, user1)
    assert Round.get(pid).users == [user1]
    task2 = insert_task(%{title: "Task#2", round_id: round.id})
    Round.add_task(pid, task2)
    assert Round.get(pid).tasks |> Enum.map(& &1.task.id) |> Enum.sort() == [task1.id, task2.id]
    refute Round.get(pid).current_task_id
    Task.start(task1_pid)
    Round.remove_user(pid, user1)
    assert Round.get(pid).users == []
    Round.remove_task(pid, task2)
    assert Round.get(pid).tasks |> Enum.map(& &1.task.id) == [task1.id]
    :timer.sleep(50)
  end
end
