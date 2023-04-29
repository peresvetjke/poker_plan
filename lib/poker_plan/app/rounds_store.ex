defmodule PokerPlan.Rounds.RoundsStore do
  use GenServer

  alias PokerPlan.Rounds

  # Client

  def start_link(opts) do
    GenServer.start_link(__MODULE__, %{}, opts)
  end

  # def get(round_id) when is_binary(round_id) do
  #   round_id
  #   |> String.to_integer()
  #   |> get()
  # end

  def get(id) when is_integer(id) do
    # IO.inspect(id, label: "rounds_store.get... id=")
    GenServer.call(__MODULE__, {:get, id})
  end

  def put(id, pid) do
    GenServer.cast(__MODULE__, {:put, id, pid})
  end

  # Callbacks

  @impl GenServer
  def init(map) do
    {:ok, map}
  end

  @impl GenServer
  def handle_call({:get, id}, _from, map) do
    {:reply, Map.get(map, id), map}
  end

  @impl GenServer
  def handle_cast({:put, id, pid}, map) do
    {:noreply, Map.put(map, id, pid)}
  end
end
