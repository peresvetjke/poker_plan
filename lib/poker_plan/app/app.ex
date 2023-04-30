defmodule PokerPlan.App do
  import Ecto.Query, warn: false

  alias PokerPlan.Repo
  alias PokerPlan.Rounds.Round

  def round_info(id) when is_integer(id) do
    id
    |> round_info_pid()
    |> Round.get()
  end

  def current_task(id) when is_integer(id) do
    round_info = round_info(id)

    case round_info.current_task_id do
      nil ->
        nil

      id ->
        round_info.round.tasks
        |> Enum.find(fn x -> x.id == id end)
    end
  end

  def current_task_users_status(id) when is_integer(id) do
    for {k, v} <- round_info(id).current_task_estimates,
        into: %{},
        do: {
          k,
          case v do
            nil -> false
            _ -> true
          end
        }
  end

  def current_task_estimates(id) when is_integer(id) do
    case current_task(id) do
      nil ->
        nil

      task ->
        case task.state do
          "finished" -> round_info(id).current_task_estimates
          _ -> nil
        end
    end
  end

  def task_estimates(id) when is_integer(id) do
    query = from e in PokerPlan.Data.Estimation, where: e.task_id == ^id
    estimates = Repo.all(query)

    Enum.reduce(estimates, %{}, fn e, acc -> Map.put(acc, e.user_id, e.value) end)
    # estimates = PokerPlan.Data.Estimation
  end

  def add_user_to_round(%PokerPlan.Data.Round{} = round, %PokerPlan.Data.User{} = user) do
    round.id
    |> round_info_pid()
    |> Round.add_user(user)

    refresh_cache(round.id)
  end

  def create_task(%{} = attrs) do
    %PokerPlan.Data.Task{}
    |> PokerPlan.Data.Task.changeset(attrs)
    |> Repo.insert()
    |> refresh_cache(:task_created)
  end

  def update_task(task_id, %{} = attrs) when is_integer(task_id) do
    PokerPlan.Data.Task
    |> Repo.get(task_id)
    |> update_task(attrs)
  end

  def change_task(%PokerPlan.Data.Task{} = task, attrs \\ %{}) do
    PokerPlan.Data.Task.changeset(task, attrs)
  end

  def update_task(%PokerPlan.Data.Task{} = task, %{} = attrs) do
    task
    |> PokerPlan.Data.Task.changeset(attrs)
    |> Repo.update()
    |> refresh_cache(:task_updated)
  end

  def start_task(%PokerPlan.Data.Task{} = task) do
    task.round_id
    |> round_info_pid()
    |> Round.set_current_task(task)

    refresh_cache(task.round_id)
  end

  def estimate_task(%PokerPlan.Data.User{} = user, %PokerPlan.Data.Task{} = task, value)
      when is_integer(value) do
    round_info_pid(task.round_id)
    |> Round.estimate_current_task(user, value)
  end

  def round_tasks(%PokerPlan.Data.Round{} = round) do
    Round.get(round_info_pid(round.id)).round.tasks
  end

  def delete_task(task_id) when is_integer(task_id) do
    Repo.get!(PokerPlan.Data.Task, task_id)
    |> delete_task()
  end

  def delete_task(%PokerPlan.Data.Task{} = task) do
    Repo.delete(task)
    |> refresh_cache(:task_deleted)
  end

  def create_estimation(task_id, user_id, value)
      when is_integer(task_id) and is_integer(user_id) and is_integer(value) do
    %PokerPlan.Data.Estimation{}
    |> PokerPlan.Data.Estimation.changeset(%{task_id: task_id, user_id: user_id, value: value})
    |> Repo.insert()
  end

  defp refresh_cache({:ok, task}, _) do
    refresh_cache(task.round_id)

    {:ok, task}
  end

  defp refresh_cache({:error, changeset}, _), do: {:error, changeset}

  defp refresh_cache(id) when is_integer(id) do
    id
    |> round_info_pid()
    |> Round.reload_round()
  end

  defp round_info_pid(id) do
    case Registry.lookup(PokerPlan.RoundRegistry, id) do
      [] ->
        {:ok, pid} = id |> load_round_with_tasks() |> Round.start_link()
        pid

      [{pid, nil}] ->
        pid
    end
  end

  defp current_task_info_pid(round_id) do
    round_info(round_id).current_task
  end

  defp load_round_with_tasks(id) when is_integer(id) do
    PokerPlan.Data.Round
    |> Repo.get!(id)
    |> Repo.preload(:tasks)
  end
end
