defmodule PokerPlan.Round do
  use GenServer

  import Ecto.Query, only: [from: 2]
  import PokerPlan.CacheHelpers

  # Client

  def start_link(%PokerPlan.Data.Round{tasks: tasks} = round) when is_list(tasks) do
    tasks_ids =
      tasks
      |> Enum.map(fn t -> t.id end)

    GenServer.start_link(
      __MODULE__,
      %{
        round: round,
        tasks_ids: tasks_ids,
        users_ids: [],
        current_task_id: nil
      },
      name: {:via, Registry, {PokerPlan.RoundRegistry, round.id}}
    )
  end

  def get(pid) do
    GenServer.call(pid, :get)
  end

  def add_user(pid, %PokerPlan.Data.User{id: id}) do
    GenServer.cast(pid, {:add, :user, id})
  end

  def remove_user(pid, user_id) when is_integer(user_id) do
    GenServer.cast(pid, {:remove, :user, user_id})
  end

  def add_task(pid, %PokerPlan.Data.Task{id: id}) do
    GenServer.cast(pid, {:add, :task, id})
  end

  def remove_task(pid, %PokerPlan.Data.Task{id: id}) do
    GenServer.cast(pid, {:remove, :task, id})
  end

  def task_processed(pid, %PokerPlan.Data.Task{} = task) do
    GenServer.cast(pid, {:task_processed, task})
  end

  def set_current_task(pid, %PokerPlan.Data.Task{id: id}) do
    GenServer.cast(pid, {:set_current_task, id})
  end

  def refresh(pid) do
    GenServer.cast(pid, :refresh)
  end

  # Callbacks

  @impl GenServer
  def init(state), do: {:ok, state}

  @impl GenServer
  def handle_call(:get, _from, state), do: {:reply, state, state}

  @impl GenServer
  def handle_cast({:add, type, id}, state)
      when is_integer(id) do
    list = Map.get(state, ids_attribute(type))

    if Enum.any?(list, fn x -> x == id end) do
      {:noreply, state}
    else
      ids = [id | Map.get(state, ids_attribute(type))]
      {:noreply, Map.put(state, ids_attribute(type), ids) |> broadcast()}
    end
  end

  @impl GenServer
  def handle_cast({:remove, type, id}, %{current_task_id: current_task_id} = state)
      when is_integer(id) do
    ids =
      Map.get(state, ids_attribute(type))
      |> List.delete(id)

    if current_task_id && type == :user do
      pid(:task, current_task_id)
      |> PokerPlan.Task.user_removed(id)
    end

    {:noreply, Map.put(state, ids_attribute(type), ids) |> broadcast()}
  end

  @impl GenServer
  def handle_cast({:task_processed, _}, %{current_task_id: nil} = state), do: {:noreply, state}

  @impl GenServer
  def handle_cast(
        {:task_processed, %PokerPlan.Data.Task{id: task_id}},
        %{current_task_id: current_task_id} = state
      )
      when is_integer(current_task_id) do
    case current_task_id do
      ^task_id -> {:noreply, %{state | current_task_id: nil} |> broadcast()}
      _ -> {:noreply, state}
    end
  end

  @impl GenServer
  def handle_cast({:set_current_task, task_id}, %{current_task_id: current_task_id} = state) do
    {:noreply, %{state | current_task_id: task_id} |> broadcast()}
  end

  @impl GenServer
  def handle_cast(:refresh, state) do
    {:noreply, state |> broadcast()}
  end

  @impl GenServer
  def handle_info({reference, :ok}, state) when is_reference(reference) do
    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:DOWN, reference, :process, pid, :normal}, state)
      when is_reference(reference) and is_pid(pid) do
    {:noreply, state}
  end

  @impl GenServer
  def handle_info(msg, state) do
    :logger.info("Unexpected message received: #{inspect(msg)}")

    {:noreply, state}
  end

  defp broadcast(state) do
    Task.async(fn ->
      Phoenix.PubSub.broadcast(
        PokerPlan.PubSub,
        "round:#{state.round.id}",
        {:round_refreshed, state}
      )
    end)

    state
  end
end
