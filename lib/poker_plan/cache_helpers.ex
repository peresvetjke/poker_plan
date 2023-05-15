defmodule PokerPlan.CacheHelpers do
  def ids_attribute(:task), do: :tasks_ids
  def ids_attribute(:user), do: :users_ids

  def load_records_using_cache(type, ids) when is_list(ids) do
    pmap(ids, fn id -> load_record_using_cache(type, id) end)
  end

  def load_record_using_cache(type, id) when is_integer(id) do
    pid = pid(type, id)
    gen_server(type).get(pid)
  end

  def pid(type, id) when is_integer(id) do
    case Registry.lookup(registry(type), id) do
      [{pid, _}] ->
        pid

      [] ->
        case gen_server(type).start_link(load_from_db(type, id)) do
          {:ok, pid} -> pid
          {:error, {:already_started, pid}} -> pid
        end
    end
  end

  def registry(:round), do: PokerPlan.RoundRegistry
  def registry(:task), do: PokerPlan.TaskRegistry
  def registry(:user), do: PokerPlan.UserRegistry

  def gen_server(:round), do: PokerPlan.Round
  def gen_server(:task), do: PokerPlan.Task
  def gen_server(:user), do: PokerPlan.User

  def load_from_db(:round, id) when is_integer(id) do
    PokerPlan.Data.Round
    |> PokerPlan.Repo.get(id)
    |> PokerPlan.Repo.preload(:tasks)
  end

  def load_from_db(:task, id) when is_integer(id) do
    PokerPlan.Data.Task
    |> PokerPlan.Repo.get(id)
    |> PokerPlan.Repo.preload(:estimations)
  end

  def load_from_db(:user, id) when is_integer(id) do
    PokerPlan.Data.User
    |> PokerPlan.Repo.get(id)
  end

  defp pmap(collection, func) do
    collection
    |> Enum.map(&Task.async(fn -> func.(&1) end))
    |> Enum.map(&Task.await/1)
  end
end
