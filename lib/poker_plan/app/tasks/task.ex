defmodule PokerPlan.Tasks.Task do
  use GenServer

  # Client

  def start_link(%PokerPlan.Data.Task{} = task, estimations \\ []) do
    GenServer.start_link(
      __MODULE__,
      %{
        data: task,
        estimations: estimations
      },
      name: {:via, Registry, {PokerPlan.TaskRegistry, task.title}}
    )
  end

  def get(pid) do
    GenServer.call(pid, :get)
  end

  def save(pid, %Ecto.Changeset{valid?: true} = changeset) do
    GenServer.cast(pid, {:save, changeset})
  end

  # Callbacks

  @impl GenServer
  def init(state) do
    {:ok, state}
  end

  @impl GenServer
  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end

  def handle_cast({:save, %Ecto.Changeset{valid?: true, data: task} = changeset}, state) do
    save_to_db(changeset)

    {:noreply, %{state | data: Ecto.Changeset.apply_changes(changeset)}}
  end

  defp save_to_db(%Ecto.Changeset{valid?: true} = changeset) do
    Task.start_link(fn -> Ecto.insert_or_update(changeset) end)
  end
end
