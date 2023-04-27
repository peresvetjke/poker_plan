defmodule PokerPlan.Rounds.Round do
  use GenServer

  # Client

  def start_link(round_id)
      when is_integer(round_id) do
    GenServer.start_link(__MODULE__, %{
      round:
        PokerPlan.Repo.get!(PokerPlan.Data.Round, round_id) |> PokerPlan.Repo.preload(:tasks),
      users: [],
      current_task: nil
    })
  end

  def get(pid) do
    GenServer.call(pid, :get)
  end

  def add_user(pid, user) do
    GenServer.cast(pid, {:add_user, user})
  end

  def set_current_task(pid, current_task) do
    GenServer.cast(pid, {:set_current_task, current_task})
  end

  # Callbacks

  @impl GenServer
  def init(round_info) do
    {:ok, round_info}
  end

  @impl GenServer
  def handle_call(:get, _from, round_info) do
    round_info
    # current_task =
    #   case round_info.current_task do
    #     nil ->
    #       {:reply, round_info, round_info}

    #     pid ->
    #       current_task = PokerPlan.TaskFSM.info(pid)
    #       {:reply, Map.put(round_info, :current_task, current_task), round_info}
    #   end
  end

  @impl GenServer
  def handle_cast({:add_user, %PokerPlan.Data.User{} = user}, round_info) do
    round_info =
      case Enum.any?(round_info.users, fn u -> u.id == user.id end) do
        true -> round_info
        false -> Map.put(round_info, :users, [user | round_info.users])
      end

    {:noreply, round_info}
  end

  @impl GenServer
  def handle_cast({:set_current_task, pid}, round_info) when is_pid(pid) do
    {:noreply, Map.put(round_info, :current_task, pid)}
  end
end
