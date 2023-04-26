defmodule PokerPlan.Rounds.Round do
  defstruct [:id, :title, :tasks, users: []]

  use GenServer

  # Client

  def to_round(%PokerPlan.Rounds.Round{} = round) do
    %PokerPlan.Data.Round{
      id: round.id,
      title: round.title,
      tasks: round.tasks
    }
  end

  def start_link(round_id)
      when is_integer(round_id) do
    GenServer.start_link(__MODULE__, build_struct(round_id))
  end

  def get(pid) do
    GenServer.call(pid, :get)
  end

  def add_user(pid, user) do
    GenServer.cast(pid, {:add_user, user})
  end

  def reload(pid) do
    round = build_struct(pid)
    GenServer.cast(pid, :reload)
  end

  # Callbacks

  @impl GenServer
  def init(round) do
    {:ok, round}
  end

  @impl GenServer
  def handle_call(:get, _from, round) do
    {:reply, round, round}
  end

  @impl GenServer
  def handle_cast({:add_user, %PokerPlan.Data.User{} = user}, round) do
    round =
      case Enum.any?(round.users, fn u -> u.id == user.id end) do
        true -> round
        false -> %__MODULE__{round | users: [user | round.users]}
      end

    {:noreply, round}
  end

  @impl GenServer
  def handle_cast(:reload, _round) do
    # round = self() |> Process.info() |> build_struct()
    # round = Process.pid() |> build_struct()
    # pid = Process.get(self(), :id)
    pid = self()
    round = build_struct(pid)

    {:noreply, round}
  end

  defp build_struct(pid) when is_pid(pid) do
    round = get(pid)
    build_struct(round.id)
  end

  defp build_struct(round_id) when is_integer(round_id) do
    PokerPlan.Data.Round
    |> PokerPlan.Repo.get(round_id)
    |> PokerPlan.Repo.preload(:tasks)
    |> build_struct()
  end

  defp build_struct(nil), do: %__MODULE__{}

  defp build_struct(%PokerPlan.Data.Round{} = round) do
    %__MODULE__{
      id: round.id,
      title: round.title,
      tasks: round.tasks,
      # tasks:
      #   round.tasks
      #   |> Enum.reduce(%{}, fn record, acc ->
      #     Map.put(acc, record.id, record)
      #   end),
      users: []
    }
  end
end
