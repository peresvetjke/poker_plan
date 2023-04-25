defmodule PokerPlan.Rounds.RoundsStore do
  use GenServer

  alias PokerPlan.Rounds

  # Client

  def start_link(opts) do
    GenServer.start_link(__MODULE__, %{}, opts)
  end

  def get(id) when is_binary(id) do
    id
    |> String.to_integer()
    |> get()
  end

  def get(id) do
    GenServer.call(__MODULE__, {:get, id})
  end

  # def put(id, round) do
  #   GenServer.cast(__MODULE__, {:put, id, round})
  # end

  # Callbacks

  @impl GenServer
  def init(map) do
    {:ok, map}
  end

  @impl GenServer
  def handle_call({:get, id}, _from, map) do
    case Map.get(map, id) do
      nil ->
        {:ok, pid} = PokerPlan.Rounds.Round.start_link(id)
        {:reply, pid, Map.put(map, id, pid)}

      pid ->
        {:reply, pid, map}
    end
  end

  # @impl GenServer
  # def handle_cast({:put, key, value}, state) do
  #   {:noreply, Map.put(state, key, value)}
  # end
end
