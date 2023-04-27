defmodule PokerPlan.TaskFSM do
  alias PokerPlan.Data.{Round, Task, User}

  # use GenServer, restart: :transient
  use GenServer

  require Logger

  def start_link(%Task{state: "idle"} = task) do
    task_info = %{
      task: task,
      votes: %{}
    }

    GenServer.start_link(__MODULE__, task_info)
  end

  def add_user(pid, user_id) when is_integer(user_id) do
    GenServer.cast(pid, {:transition, :add_user, user_id})
  end

  def remove_user(pid, user_id) when is_integer(user_id) do
    GenServer.cast(pid, {:transition, :remove_user, user_id})
  end

  def vote(pid, user_id, value) when is_integer(user_id) and is_integer(value) do
    GenServer.cast(pid, {:transition, :vote, user_id, value})
  end

  def start(pid) do
    GenServer.cast(pid, {:transition, :start})
  end

  def finish(pid) do
    GenServer.cast(pid, {:transition, :finish})
  end

  def info(pid) do
    GenServer.call(pid, :info)
  end

  @impl GenServer
  def init(state), do: {:ok, state}

  @impl GenServer
  def handle_cast(
        {:transition, :add_user, user_id},
        %{task: %Task{state: state} = task, votes: %{} = votes} = info
      )
      when is_integer(user_id) do
    case state do
      "idle" -> {:noreply, %{task: task, votes: Map.put(votes, user_id, nil)}}
      "doing" -> {:noreply, %{task: task, votes: Map.put(votes, user_id, nil)}}
      _ -> info
    end
  end

  @impl GenServer
  def handle_cast(
        {:transition, :remove_user, user_id},
        %{task: %Task{state: state} = task, votes: %{} = votes} = info
      )
      when is_integer(user_id) do
    case state do
      "idle" ->
        {:noreply, %{task: task, votes: Map.delete(votes, user_id)}}

      "doing" ->
        votes = Map.delete(votes, user_id)

        if Map.values(votes) |> Enum.all?() do
          {:noreply, %{task: %Task{task | state: "finished"}, votes: votes}}
        else
          {:noreply, %{task: task, votes: votes}}
        end

      _ ->
        info
    end
  end

  @impl GenServer
  def handle_cast(
        {:transition, :vote, user_id, value},
        %{task: %Task{state: state} = task, votes: %{} = votes} = info
      )
      when is_integer(user_id) and is_integer(value) do
    case state do
      "doing" ->
        votes = Map.put(votes, user_id, value)

        if Map.values(votes) |> Enum.all?() do
          {:noreply, %{task: %Task{task | state: "finished"}, votes: votes}}
        else
          {:noreply, %{task: task, votes: votes}}
        end

      _ ->
        info
    end
  end

  @impl GenServer
  def handle_cast(
        {:transition, :start},
        %{task: %Task{state: "idle"} = task, votes: %{}} = task_info
      ) do
    case Task.changeset(task, %{state: "doing"}) do
      {:ok, task} -> Repo.update(task)
      changeset -> task
    end

    {:noreply, %{task: %Task{task | state: "doing"}, votes: %{}}}
  end

  @impl GenServer
  def handle_cast({:transition, transition}, %Task{state: state} = issue) do
    Logger.warn(inspect({:error, {:not_allowed, transition, state}}))
    {:noreply, issue}
  end

  @impl GenServer
  def handle_call(:info, _from, info) do
    {:reply, info, info}
  end
end
