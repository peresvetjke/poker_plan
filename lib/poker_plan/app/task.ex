defmodule PokerPlan.Rounds.Task do
  import Ecto.Query, only: [from: 2]

  alias PokerPlan.Repo
  alias PokerPlan.Data.{Round, Task, User}

  # use GenServer, restart: :transient
  use GenServer

  require Logger

  # def start_link(%PokerPlan.Data.Task{state: "idle"} = task) do
  def start_link(%PokerPlan.Data.Task{} = task, users \\ []) do
    estimates = Enum.reduce(users, %{}, fn user, acc -> Map.put(acc, user.id, nil) end)

    task_info = %{
      task: task,
      estimates: estimates
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

  def stop(pid) do
    GenServer.cast(pid, {:transition, :stop})
  end

  def finish(pid) do
    GenServer.cast(pid, {:transition, :finish})
  end

  def get(pid) do
    GenServer.call(pid, :get)
  end

  @impl GenServer
  def init(state), do: {:ok, state}

  @impl GenServer
  def handle_cast(
        {:transition, :add_user, user_id},
        %{
          task: %PokerPlan.Data.Task{state: state} = task,
          estimates: %{} = estimates
        } = info
      )
      when is_integer(user_id) do
    case state do
      "idle" -> {:noreply, %{task: task, estimates: Map.put(estimates, user_id, nil)}}
      "doing" -> {:noreply, %{task: task, estimates: Map.put(estimates, user_id, nil)}}
      _ -> info
    end
  end

  @impl GenServer
  def handle_cast(
        {:transition, :remove_user, user_id},
        %{task: %PokerPlan.Data.Task{state: state} = task, estimates: %{} = estimates} = info
      )
      when is_integer(user_id) do
    case state do
      "idle" ->
        {:noreply, %{task: task, estimates: Map.delete(estimates, user_id)}}

      "doing" ->
        estimates = Map.delete(estimates, user_id)

        if Map.values(estimates) |> Enum.all?() do
          {:noreply,
           %{task: %PokerPlan.Data.Task{task | state: "finished"}, estimates: estimates}}
        else
          {:noreply, %{task: task, estimates: estimates}}
        end

      _ ->
        info
    end
  end

  @impl GenServer
  def handle_cast(
        {:transition, :vote, user_id, value},
        %{task: %PokerPlan.Data.Task{state: state} = task, estimates: %{} = estimates} = info
      )
      when is_integer(user_id) and is_integer(value) do
    IO.inspect(state, label: "voting, state")

    case state do
      "doing" ->
        estimates = Map.put(estimates, user_id, value)

        if Map.values(estimates) |> Enum.all?() do
          {:ok, task} = PokerPlan.Tasks.update_task(task, %{state: "finished"})
        end

        {:noreply, %{task: task, estimates: estimates}}

      _ ->
        {:noreply, info}
    end
  end

  @impl GenServer
  def handle_cast(
        {:transition, :start},
        %{task: %PokerPlan.Data.Task{state: "idle"}} = task_info
      ),
      do: do_start(task_info)

  @impl GenServer
  def handle_cast(
        {:transition, :start},
        %{task: %PokerPlan.Data.Task{state: "doing"}} = task_info
      ),
      do: do_start(task_info)

  defp do_start(task_info) do
    round_id = task_info.task.round_id

    Repo.update_all(
      from(t in PokerPlan.Data.Task, where: t.round_id == ^round_id),
      set: [state: "idle"]
    )

    {:ok, _} = PokerPlan.Tasks.update_task(task_info.task, %{state: "doing"})

    {:noreply, task_info}
  end

  @impl GenServer
  def handle_cast({:transition, :stop}, %{task: %PokerPlan.Data.Task{} = task, estimates: %{}}) do
    {:ok, _} = PokerPlan.Tasks.update_task(task, %{state: "idle"})

    {:stop, :normal, "Stopping the task process"}
  end

  @impl GenServer
  def handle_call(
        :get,
        _from,
        %{
          task: %PokerPlan.Data.Task{state: "finished"} = task,
          estimates: %{} = estimates
        } = info
      ) do
    {:reply, info, info}
  end

  @impl GenServer
  def handle_call(
        :get,
        _from,
        %{task: %PokerPlan.Data.Task{} = task, estimates: %{} = estimates} = info
      ) do
    estimates =
      for {k, v} <- estimates,
          into: %{},
          do: {
            k,
            case v do
              nil -> false
              _ -> true
            end
          }

    {:reply, %{task: task, estimates: estimates}, info}
  end
end
