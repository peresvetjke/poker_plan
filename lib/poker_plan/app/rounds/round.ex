defmodule PokerPlan.Rounds.Round do
  use GenServer

  import Ecto.Query, only: [from: 2]
  # Client

  def start_link(%PokerPlan.Data.Round{} = round) do
    GenServer.start_link(
      __MODULE__,
      %{
        round: round,
        users: [],
        current_task_id: nil,
        current_task_estimates: %{}
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

  def set_current_task(pid, %PokerPlan.Data.Task{} = current_task) do
    GenServer.cast(pid, {:set_current_task, current_task})
  end

  def estimate_current_task(pid, %PokerPlan.Data.User{} = user, value) do
    GenServer.cast(pid, {:estimate_current_task, user, value})
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
  def handle_cast(
        {:add_user, %PokerPlan.Data.User{} = user},
        %{current_task_estimates: current_task_estimates, users: users} = round_info
      ) do
    case Enum.any?(round_info.users, fn u -> u.id == user.id end) do
      true ->
        {:noreply, round_info}

      false ->
        Phoenix.PubSub.broadcast(
          PokerPlan.PubSub,
          "round:#{round_info.round.id}",
          {:round_refreshed, round_info}
        )

        {:noreply,
         %{
           round_info
           | users: [user | round_info.users],
             current_task_estimates: Map.put(current_task_estimates, user.id, nil)
         }}

        # round_info =
        #   Map.put(round_info, :users, [user | round_info.users])
        #   |> Map.put(:current_task_estimates, nil)
    end
  end

  @impl GenServer
  def handle_cast({:set_current_task, %PokerPlan.Data.Task{state: "doing"} = task}, round_info) do
    round_info =
      round_info
      |> Map.put(:current_task_id, nil)
      |> Map.put(:current_task_estimations, %{})

    PokerPlan.App.update_task(task, %{state: "idle"})

    {:noreply, round_info}
  end

  @impl GenServer
  def handle_cast(
        {:set_current_task, %PokerPlan.Data.Task{state: "idle"} = task},
        %{current_task_id: current_task_id} = round_info
      )
      when is_nil(current_task_id) do
    # round_info =
    #   round_info
    #   |> Map.put(:current_task_id, task.id)
    #   |> Map.put(:current_task_estimations, %{})

    {:ok, task} = PokerPlan.App.update_task(task, %{state: "doing"})

    {:noreply,
     round_info
     |> Map.put(:current_task_id, task.id)
     |> Map.put(:current_task_estimations, %{})}
  end

  @impl GenServer
  def handle_cast(
        {:set_current_task, %PokerPlan.Data.Task{state: "idle"} = task},
        %{current_task_id: current_task_id} = round_info
      )
      when is_integer(current_task_id) do
    previous_task =
      round_info.round.tasks
      |> Enum.find(fn x -> x.id == current_task_id end)

    PokerPlan.App.update_task(previous_task, %{state: "idle"})

    round_info =
      round_info
      |> Map.put(:current_task_id, task.id)
      |> Map.put(:current_task_estimations, nil)

    {:ok, task} = PokerPlan.App.update_task(task, %{state: "doing"})

    {:noreply, Map.put(round_info, :current_task_id, task.id)}
  end

  @impl GenServer
  def handle_cast(
        {:estimate_current_task, user, value},
        %{
          current_task_estimates: current_task_estimates,
          current_task_id: current_task_id,
          round: round
        } = round_info
      )
      when is_integer(value) do
    estimates = Map.put(current_task_estimates, user.id, value)

    round_info =
      if Map.values(estimates) |> Enum.all?() do
        task =
          round_info.round.tasks
          |> Enum.find(fn x -> x.id == round_info.current_task_id end)

        Enum.each(estimates, fn {user_id, points} ->
          PokerPlan.App.create_estimation(task.id, user.id, points)
        end)

        PokerPlan.App.update_task(task, %{state: "finished"})

        Phoenix.PubSub.broadcast(
          PokerPlan.PubSub,
          "round:#{round_info.round.id}",
          {:task_estimation_report, estimates}
        )

        round_info
        |> Map.put(:current_task_estimates, %{})
        |> Map.put(:current_task_id, nil)
      else
        round_info
        # IO.inspect(round_info.current_task_id, label: "round_info.current_task_id (in block)")
      end

    # IO.inspect(round_info.current_task_id, label: "round_info.current_task_id (out of block)")

    Phoenix.PubSub.broadcast(
      PokerPlan.PubSub,
      "round:#{round_info.round.id}",
      {:round_refreshed, round_info}
    )

    {:noreply, round_info}
  end

  # @impl GenServer
  # def handle_cast(:clear_current_task, round_info) do
  #   Phoenix.PubSub.broadcast(
  #     PokerPlan.PubSub,
  #     "round:#{round_info.round.id}",
  #     :current_task_deleted
  #   )

  #   {:noreply, Map.put(round_info, :current_task, nil)}
  # end
end
