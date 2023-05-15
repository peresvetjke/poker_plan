defmodule PokerPlan.User do
  use GenServer

  # Client

  def start_link(%PokerPlan.Data.User{id: id} = user) when is_integer(id) do
    GenServer.start_link(
      __MODULE__,
      user,
      name: {:via, Registry, {PokerPlan.UserRegistry, user.id}}
    )
  end

  def get(pid) do
    GenServer.call(pid, :get)
  end

  def update(pid, %Ecto.Changeset{valid?: true} = changeset) do
    GenServer.cast(pid, {:update, changeset})
  end

  # Callbacks

  @impl GenServer
  def init(user) do
    {:ok, user}
  end

  @impl GenServer
  def handle_call(:get, _from, user) do
    {:reply, user, user}
  end

  @impl GenServer
  def handle_cast({:update, changeset}, _user) do
    user = Ecto.Changeset.apply_changes(changeset)

    {:noreply, user}
  end
end
