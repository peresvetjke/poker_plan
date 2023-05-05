defmodule PokerPlan.Tasks.TasksStoreTest do
  use PokerPlan.DataCase, async: false

  alias PokerPlan.Tasks.TasksStore

  test "base" do
    user1 = insert_user(%{email: "user1@example.com"})
    user2 = insert_user(%{email: "user2@example.com"})
    round = insert_round(%{title: "Round#1"})
    task = insert_task(%{title: "Task#1", round_id: round.id})

    {:ok, pid} = TasksStore.start_link(round)

    IO.inspect(TasksStore.get(pid), label: "Store.get(pid)")

    # {:error, {:already_started, ^pid}} = TasksStore.start_link(round)
    # Process.exit(pid, :kill)
    # GenServer.cast({:via, Registry, {PokerPlan.TasksStoreRegistry, round.id}}, :terminate)
    # Process.sleep(100)
    # {:ok, pid} = TasksStore.start_link(round)
    IO.inspect(TasksStore.get(pid), label: "Store.get(pid)")
    # task = %PokerPlan.Data.Task{title: "title", round_id: round.id}
    # {:ok, pid} = Task.start_link(task)
    # assert Task.get(pid).data.title == "title"

    # changeset =
    #   PokerPlan.Data.Task.changeset(task, %{title: "title2"})
    #   |> IO.inspect(label: "changeset")

    # IO.inspect(changeset.data, label: "changeset.data")
    # IO.inspect(changeset.changes.title, label: "changeset.changes.title")

    # IO.inspect(Ecto.Changeset.apply_changes(changeset),
    #   label: "Ecto.Changeset.apply_changes(changeset)"
    # )

    # Task.save(pid, changeset)
    # # :timer.sleep(500)
    # assert Task.get(pid).data.title == "title2"
    # # refute PokerPlan.Data.Task.changeset(task, %{title: ""}).valid?
    # # assert PokerPlan.Data.Task.changeset(task, %{title: "title2"}).valid?

    # # changeset = PokerPlan.Data.Task.changeset(task, %{title: "title2"})

    # # IO.inspect(changeset.data, label: "data")
    # #
    # # changeset.changes
    # # |> PokerPlan.Repo.insert_or_update()
    # # |> IO.inspect()
    # # IO.inspect(changeset, label: "changeset")
    # # IO.inspect(changeset.data, label: "changeset.data")
    # # IO.inspect(%{changeset.data | changeset.changes})
    # # IO.inspect(PokerPlan.Data.Task.changeset(task, %{title: "title2"}), label: "changeset")
    # # Task.create_task(task)
    # # {:ok, pid} =

    # # task_pid =
    # #   Repo.get_by(PokerPlan.Data.Task, title: "title")
    # #   |> IO.inspect(label: "Repo.get_by(...)")

    # # IO.inspect

    # # create task
  end
end
