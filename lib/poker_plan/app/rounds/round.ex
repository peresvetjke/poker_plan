defmodule PokerPlan.Rounds.Round do
  use GenServer

  # Client

  def start_link(%PokerPlan.Data.Round{} = round) do
    GenServer.start_link(
      __MODULE__,
      %{
        round: round,
        users: [],
        current_task: nil
      },
      name: {:via, Registry, {PokerPlan.RoundRegistry, round.id}}
    )
  end

  def get(pid) do
    GenServer.call(pid, :get)
  end

  def reload_round(pid) do
    GenServer.cast(pid, :reload_round)
  end

  def add_user(pid, %PokerPlan.Data.User{} = user) do
    GenServer.cast(pid, {:add_user, user})
  end

  def add_task(pid, %PokerPlan.Data.Task{} = task) do
    GenServer.cast(pid, {:add_task, task})
  end

  def set_current_task(pid, %PokerPlan.Data.Task{} = current_task) do
    GenServer.cast(pid, {:set_current_task, current_task})
  end

  def clear_current_task(pid) do
    GenServer.cast(pid, :clear_current_task)
  end

  # Callbacks

  @impl GenServer
  def init(round_info) do
    {:ok, round_info}
  end

  @impl GenServer
  def handle_call(:get, _from, round_info) do
    {:reply, round_info, round_info}
  end

  @impl GenServer
  def handle_cast(:reload_round, %{round: round} = round_info) do
    round = PokerPlan.Repo.get!(PokerPlan.Data.Round, round.id) |> PokerPlan.Repo.preload(:tasks)
    round_info = Map.put(round_info, :round, round)
    # :timer.sleep(500)
    # IO.inspect(round.tasks, label: "reloading round, round.tasks")

    Phoenix.PubSub.broadcast(
      PokerPlan.PubSub,
      "round:#{round_info.round.id}",
      {:round_refreshed, round_info}
    )

    {:noreply, round_info}
  end

  @impl GenServer
  def handle_cast({:add_user, %PokerPlan.Data.User{} = user}, round_info) do
    round_info =
      case Enum.any?(round_info.users, fn u -> u.id == user.id end) do
        true ->
          round_info

        false ->
          Phoenix.PubSub.broadcast(
            PokerPlan.PubSub,
            "round:#{round_info.round.id}",
            {:user_joined, user}
          )

          Map.put(round_info, :users, [user | round_info.users])
      end

    case round_info.current_task do
      nil -> nil
      pid -> PokerPlan.Rounds.CurrentTask.add_user(pid, user.id)
    end

    {:noreply, round_info}
  end

  # @impl GenServer
  # def handle_cast({:add_task, %PokerPlan.Data.Task{} = task}, round_info) do
  #   round_info =
  #     case Enum.any?(round_info.users, fn u -> u.id == user.id end) do
  #       true ->
  #         round_info

  #       false ->
  #         Phoenix.PubSub.broadcast(
  #           PokerPlan.PubSub,
  #           "round:#{round_info.round.id}",
  #           {:user_joined, user}
  #         )

  #         Map.put(round_info, :users, [user | round_info.users])
  #     end

  #   {:noreply, round_info}
  # end

  @impl GenServer
  def handle_cast({:set_current_task, %PokerPlan.Data.Task{} = task}, round_info) do
    case round_info.current_task do
      nil -> nil
      previous_task_pid -> PokerPlan.Rounds.CurrentTask.stop(previous_task_pid)
    end

    {:ok, task_pid} = PokerPlan.Rounds.CurrentTask.start_link(task, round_info.users)
    # PokerPlan.Rounds.CurrentTask.start(task_pid)
    task_info = PokerPlan.Rounds.CurrentTask.get(task_pid)

    Phoenix.PubSub.broadcast(
      PokerPlan.PubSub,
      "round:#{round_info.round.id}",
      {:task_started, task_info}
    )

    {:noreply, Map.put(round_info, :current_task, task_pid)}
  end

  @impl GenServer
  def handle_cast(:clear_current_task, round_info) do
    Phoenix.PubSub.broadcast(
      PokerPlan.PubSub,
      "round:#{round_info.round.id}",
      :current_task_deleted
    )

    {:noreply, Map.put(round_info, :current_task, nil)}
  end
end
