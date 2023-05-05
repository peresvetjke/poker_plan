defmodule PokerPlan.Tasks.TasksStore do
  use GenServer

  import Ecto.Query, only: [from: 2]

  # Client

  def start_link(%PokerPlan.Data.Round{id: id} = round) do
    round_id = round.id

    tasks =
      from(t in PokerPlan.Data.Task,
        where:
          t.round_id ==
            ^round_id
      )
      |> PokerPlan.Repo.all()

    tasks_map =
      tasks
      |> Enum.reduce(%{}, fn t, acc -> Map.put(acc, t.id, t) end)

    GenServer.start_link(
      __MODULE__,
      tasks_map,
      name: {:via, Registry, {PokerPlan.TasksStoreRegistry, round.id}}
    )
  end

  def get(pid) do
    GenServer.call(pid, :get)
  end

  # def save(pid, %Ecto.Changeset{valid?: true} = changeset) do
  #   GenServer.cast(pid, {:save, changeset})
  # end

  # Callbacks

  @impl GenServer
  def init(state) do
    {:ok, state}
  end

  @impl GenServer
  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end

  # def handle_cast({:save, %Ecto.Changeset{valid?: true, data: task} = changeset}, state) do
  #   save_to_db(changeset)

  #   {:noreply, %{state | data: Ecto.Changeset.apply_changes(changeset)}}
  # end

  # defp save_to_db(%Ecto.Changeset{valid?: true} = changeset) do
  #   Task.start_link(fn -> Ecto.insert_or_update(changeset) end)
  # end
end
