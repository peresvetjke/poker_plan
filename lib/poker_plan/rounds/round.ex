defmodule PokerPlan.Rounds.Round do
  defstruct [:id, :title, :tasks, users: []]

  use GenServer

  # Client

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
      users: []
    }
  end
end
