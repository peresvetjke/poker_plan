defmodule PokerPlan.TaskTest do
  use PokerPlan.DataCase, async: false

  import Ecto.Query, only: [from: 2]
  alias PokerPlan.{Repo, Round, Task}

  test "base" do
    user1 = insert_user(%{email: "user1@example.com"})
    user2 = insert_user(%{email: "user2@example.com"})
    spectator = insert_user(%{email: "spectator@example.com", is_spectator: true})
    user1_id = user1.id
    user2_id = user2.id
    spectator_id = spectator.id
    round = insert_round(%{title: "Round#1"})

    round =
      Repo.get(PokerPlan.Data.Round, round.id)
      |> Repo.preload(:tasks)

    task1 =
      insert_task(%{task: "Task#1", round_id: round.id})
      |> Repo.preload(:estimations)

    task2 =
      insert_task(%{task: "Task#2", round_id: round.id})
      |> Repo.preload(:estimations)

    task1_id = task1.id
    task2_id = task2.id

    {:ok, round_pid} = Round.start_link(round)
    Round.add_user(round_pid, user1)
    Round.add_user(round_pid, user2)
    Round.add_user(round_pid, spectator)

    # :timer.sleep(100)
    {:ok, task1_pid} = Task.start_link(task1)
    {:ok, task2_pid} = Task.start_link(task2)
    assert Task.get(task1_pid).estimations == []
    assert Task.get(task1_pid).task.state == "idle"
    refute Round.get(round_pid).current_task_id
    Task.start(task1_pid)
    :timer.sleep(100)
    assert Task.get(task1_pid).task.state == "doing"
    assert Round.get(round_pid).current_task_id == task1.id
    assert Task.get(task1_pid).estimations == []

    # :timer.sleep(100)
    Task.estimate(task1_pid, user1, 1)

    assert [%PokerPlan.Data.Estimation{user_id: ^user1_id, task_id: ^task1_id, value: 1}] =
             Task.get(task1_pid).estimations

    Task.start(task2_pid)
    :timer.sleep(100)
    assert Task.get(task1_pid).task.state == "idle"
    assert Task.get(task1_pid).task.estimations == []
    assert Task.get(task2_pid).task.state == "doing"

    Task.estimate(task2_pid, user1, 1)
    :timer.sleep(100)

    assert [%PokerPlan.Data.Estimation{user_id: ^user1_id, task_id: ^task2_id, value: 1}] =
             Task.get(task2_pid).estimations

    Task.estimate(task2_pid, user1, 1)
    Task.stop(task2_pid)
    assert Task.get(task2_pid).task.state == "idle"
    assert Task.get(task2_pid).estimations == []
    Task.start(task2_pid)
    Task.estimate(task2_pid, user1, 1)
    Task.estimate(task2_pid, spectator, 5)

    assert [%PokerPlan.Data.Estimation{user_id: ^user1_id, task_id: ^task2_id, value: 1}] =
             Task.get(task2_pid).estimations

    Task.estimate(task2_pid, user1, 2)

    assert [%PokerPlan.Data.Estimation{user_id: ^user1_id, task_id: ^task2_id, value: 2}] =
             Task.get(task2_pid).estimations

    assert Task.get(task2_pid).task.state == "doing"
    Task.estimate(task2_pid, user2, 5)

    :timer.sleep(200)
    assert Repo.get(PokerPlan.Data.Task, task2.id).state == "finished"
    query = from(e in PokerPlan.Data.Estimation, where: e.task_id == ^task2_id)

    estimations = Repo.all(query)

    assert [
             %PokerPlan.Data.Estimation{user_id: ^user1_id, value: 2},
             %PokerPlan.Data.Estimation{user_id: ^user2_id, value: 5}
           ] = estimations
  end
end
