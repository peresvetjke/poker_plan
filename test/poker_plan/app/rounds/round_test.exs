defmodule PokerPlan.Rounds.RoundTest do
  use PokerPlan.DataCase, async: false

  # alias PokerPlan.{Rounds, Tasks}
  alias PokerPlan.Repo
  alias PokerPlan.Rounds.Round
  # alias PokerPlan.Data.{Task}

  test "base" do
    user1 = insert_user(%{email: "user1@example.com"})
    user2 = insert_user(%{email: "user2@example.com"})
    round = insert_round(%{title: "Round#1"})
    {:ok, pid} = Round.start_link(round)
    round_info = Round.get(pid)
    assert round_info.round.title == "Round#1"
    assert round_info.users == []
    Round.add_user(pid, user1)
    round_info = Round.get(pid)
    assert round_info.users == [user1]
    assert round_info.round.tasks == []
    {:ok, task1} = Tasks.create_task(%{round_id: round.id, title: "Task#1"})
    round_info = Round.get(pid)
    assert round_info.round.tasks == [task1]
    # assert round_info.round.tasks == []
    # {:ok, task1} = Tasks.create_task(%{round_id: round.id, title: "Task#1"})
    # round_info = Rounds.get_round_info!(round.id)
    # assert round_info.round.tasks == [task1]
    # assert task1.state == "idle"
    # refute round_info.current_task
    # Rounds.start_task(task1)
    # refute round_info.current_task
    # # round_info = Rounds.get_round_info!(round.id)
    # # [task] = round_info.round.tasks
    # # :ok =
    # task1
    # |> Task.changeset(%{state: "doing"})
    # |> Repo.update()

    # round_info = Rounds.get_round_info!(round.id)
    # # Repo.update(task1, )
    # [task1] = round_info.round.tasks
    # assert task1.state == "doing"
  end
end
