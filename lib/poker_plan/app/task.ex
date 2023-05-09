defmodule PokerPlan.Task do
  use GenServer

  import Ecto.Changeset, only: [apply_changes: 1]
  import PokerPlan.CacheHelpers

  alias PokerPlan.Round

  # Client

  def start_link(%PokerPlan.Data.Task{id: id, estimations: estimations} = task)
      when is_integer(id) and is_list(estimations) do
    GenServer.start_link(
      __MODULE__,
      %{task: task, estimations: estimations, estimations_map: %{}},
      name: {:via, Registry, {PokerPlan.TaskRegistry, task.id}}
    )
  end

  def get(pid) do
    GenServer.call(pid, :get)
  end

  def get_user_estimation(pid, user_id) when is_integer(user_id) do
    GenServer.call(pid, {:get_user_estimation, user_id})
  end

  def switch_state(pid) do
    GenServer.cast(pid, :switch_state)
    GenServer.cast(pid, :refresh_round)
  end

  def start(pid) do
    GenServer.cast(pid, :start)
    GenServer.cast(pid, :refresh_round)
  end

  def stop(pid) do
    GenServer.cast(pid, :stop)
    GenServer.cast(pid, :refresh_round)
  end

  def user_removed(pid, user_id) when is_integer(user_id) do
    GenServer.cast(pid, {:user_removed, user_id})
    GenServer.cast(pid, :check_estimation_status)
    GenServer.cast(pid, :refresh_round)
    GenServer.cast(pid, :estimation_report)
  end

  def estimate(pid, %PokerPlan.Data.User{} = user, value) when is_integer(value) do
    GenServer.cast(pid, {:estimate, user, value})
    GenServer.cast(pid, :check_estimation_status)
    GenServer.cast(pid, :refresh_round)
    GenServer.cast(pid, :estimation_report)
  end

  # Callbacks

  @impl GenServer
  def init(state) do
    {:ok, state}
  end

  @impl GenServer
  def handle_call(
        :get,
        _from,
        %{task: %PokerPlan.Data.Task{id: task_id, state: "finished"}, estimations: estimations} =
          state
      ) do
    {:reply, state, state}
  end

  @impl GenServer
  def handle_call(
        :get,
        _from,
        %{estimations_map: %{} = estimations_map} = state
      ) do
    response =
      state
      |> Map.delete(:estimations_map)
      |> Map.put(:voted_users_ids, Map.keys(estimations_map))

    {:reply, response, state}
  end

  @impl GenServer
  def handle_call(
        {:get_user_estimation, user_id},
        _from,
        %{estimations_map: %{} = estimations_map} = state
      ) do
    {:reply, Map.get(estimations_map, user_id), state}
  end

  @impl GenServer
  def handle_cast(:stop, %{task: %PokerPlan.Data.Task{state: "finished"}} = state) do
    :logger.info("IGNORED: Tried to stop finished task.")

    {:noreply, state}
  end

  @impl GenServer
  def handle_cast(:stop, %{task: %PokerPlan.Data.Task{state: "idle"}} = state) do
    :logger.info("IGNORED: Tried to stop idle task.")

    {:noreply, state}
  end

  @impl GenServer
  def handle_cast(
        :stop,
        %{task: %PokerPlan.Data.Task{state: "doing", round_id: round_id} = task} = state
      ) do
    pid(:round, round_id)
    |> Round.task_processed(task)

    {:noreply, switch_task_state(state, "idle")}
  end

  @impl GenServer
  def handle_cast(:start, %{task: %PokerPlan.Data.Task{state: "finished"}} = state) do
    :logger.info("IGNORED: Tried to start finished task.")

    {:noreply, state}
  end

  @impl GenServer
  def handle_cast(:start, %{task: %PokerPlan.Data.Task{state: "doing"} = task} = state) do
    :logger.info("IGNORED: Tried to start doing task.")

    {:noreply, state}
  end

  @impl GenServer
  def handle_cast(
        :start,
        %{task: %PokerPlan.Data.Task{id: id, state: "idle", round_id: round_id} = task} = state
      ) do
    round_pid = pid(:round, round_id)
    round = Round.get(round_pid)

    case round.current_task_id do
      nil -> nil
      id -> pid(:task, id) |> stop()
    end

    Round.set_current_task(round_pid, task)

    {:noreply, switch_task_state(state, "doing")}
  end

  @impl GenServer
  def handle_cast({:estimate, %PokerPlan.Data.User{is_spectator: true} = user, value}, state)
      when is_integer(value) do
    :logger.info("IGNORED: Spectator tried to estimate task.")

    {:noreply, state}
  end

  @impl GenServer
  def handle_cast(
        {:estimate, %PokerPlan.Data.User{} = user, value},
        %{task: %PokerPlan.Data.Task{state: "finished"}} = state
      )
      when is_integer(value) do
    :logger.info("IGNORED: User tried to estimate finished task.")

    {:noreply, state}
  end

  @impl GenServer
  def handle_cast(
        {:estimate, %PokerPlan.Data.User{} = user, value},
        %{task: %PokerPlan.Data.Task{state: "idle"}} = state
      )
      when is_integer(value) do
    :logger.info("IGNORED: User tried to estimate idle task.")

    {:noreply, state}
  end

  @impl GenServer
  def handle_cast(
        {:estimate, %PokerPlan.Data.User{id: user_id} = user, value},
        %{
          task: %PokerPlan.Data.Task{id: task_id, state: "doing", round_id: round_id} = task,
          estimations_map: %{} = estimations_map
        } = state
      )
      when is_integer(value) do
    estimations_map =
      case Map.get(estimations_map, user_id) do
        nil -> Map.put(estimations_map, user_id, value)
        ^value -> Map.delete(estimations_map, user_id)
        _other_value -> Map.put(estimations_map, user_id, value)
      end

    {:noreply, %{state | estimations_map: estimations_map}}
  end

  @impl GenServer
  def handle_cast(
        {:user_removed, user_id},
        %{estimations_map: estimations_map} = state
      )
      when is_integer(user_id) do
    {:noreply,
     %{
       state
       | estimations_map: Map.delete(estimations_map, user_id)
     }}
  end

  @impl GenServer
  def handle_cast(
        :check_estimation_status,
        %{
          task: %PokerPlan.Data.Task{id: task_id, round_id: round_id} = task,
          estimations_map: estimations_map
        } = state
      ) do
    round_pid = pid(:round, round_id)
    users_ids = PokerPlan.Round.get(round_pid).users_ids

    remaining_users_ids =
      load_records_using_cache(:user, users_ids)
      |> Enum.reject(fn u -> u.is_spectator == true || Map.has_key?(estimations_map, u.id) end)

    if Enum.empty?(remaining_users_ids) do
      changeset =
        PokerPlan.Data.Task.changeset(task, %{
          state: "finished",
          estimations:
            Enum.map(estimations_map, fn {user_id, value} ->
              %{task_id: task_id, user_id: user_id, value: value}
            end)
        })

      task = PokerPlan.Repo.insert_or_update!(changeset)

      Round.task_processed(round_pid, task)

      {:noreply,
       %{
         state
         | task: task,
           estimations: task.estimations
       }}
    else
      {:noreply, state}
    end
  end

  @impl GenServer
  def handle_cast(
        :refresh_round,
        %{task: %PokerPlan.Data.Task{round_id: round_id}} = state
      ) do
    pid(:round, round_id)
    |> PokerPlan.Round.refresh()

    {:noreply, state}
  end

  @impl GenServer
  def handle_cast(
        :estimation_report,
        %{task: %PokerPlan.Data.Task{id: task_id, round_id: round_id, state: "finished"}} = state
      ) do
    Phoenix.PubSub.broadcast(
      PokerPlan.PubSub,
      "round:#{round_id}",
      {:task_estimation_report, round_id, task_id}
    )

    {:noreply, state}
  end

  @impl GenServer
  def handle_cast(:estimation_report, state) do
    :logger.info("Tried to display estimation report for a not finished task.")

    {:noreply, state}
  end

  @impl GenServer
  def handle_info({reference, %PokerPlan.Data.Task{}}, state) when is_reference(reference) do
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

  defp switch_task_state(state, new_task_state) do
    changeset = PokerPlan.Data.Task.changeset(state.task, %{state: new_task_state})
    save_to_db(changeset)
    %{state | task: apply_changes(changeset), estimations: %{}}
  end

  defp save_to_db(%Ecto.Changeset{valid?: true} = changeset) do
    Task.async(fn -> PokerPlan.Repo.insert_or_update!(changeset) end)
  end
end
