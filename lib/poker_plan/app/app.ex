defmodule PokerPlan.App do
  import Ecto.Query, warn: false

  alias PokerPlan.Repo
  alias PokerPlan.Rounds.Round

  def round_info(id) when is_integer(id) do
    id
    |> round_info_pid()
    |> Round.get()
  end

  def current_task_info(id) when is_integer(id) do
    case round_info(id).current_task do
      nil -> nil
      pid -> PokerPlan.Rounds.CurrentTask.get(pid)
    end
  end

  def current_task(id) when is_integer(id) do
    current_task_info(id).task
  end

  def current_task_users_status(id) when is_integer(id) do
    for {k, v} <- current_task_info(id).estimates,
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
    IO.inspect(current_task_info(id).task, label: "current_task_info(id).task")

    case current_task_info(id).task do
      %PokerPlan.Data.Task{state: "finished"} -> current_task_info(id).estimates
      _ -> nil
    end
  end

  def add_user_to_round(%PokerPlan.Data.Round{} = round, %PokerPlan.Data.User{} = user) do
    round.id
    |> round_info_pid()
    |> Round.add_user(user)
  end

  def create_task(%{} = attrs) do
    %PokerPlan.Data.Task{}
    |> PokerPlan.Data.Task.changeset(attrs)
    |> Repo.insert()
    |> refresh_cache(:task_created)
  end

  def update_task(%PokerPlan.Data.Task{} = task, %{} = attrs) do
    task
    |> PokerPlan.Data.Task.changeset(attrs)
    |> Repo.update()
    |> refresh_cache(:task_updated)
  end

  def start_task(%PokerPlan.Data.Task{} = task) do
    # Round.start_task(task)
    task.round_id
    |> round_info_pid()
    |> Round.set_current_task(task)

    refresh_cache(task.round_id)
  end

  def estimate_task(%PokerPlan.Data.User{} = user, %PokerPlan.Data.Task{} = task, value)
      when is_integer(value) do
    current_task_info_pid(task.round_id)
    |> PokerPlan.Rounds.CurrentTask.vote(user.id, value)
  end

  def get_round_tasks(%PokerPlan.Data.Round{} = round) do
    Round.get(round_info_pid(round.id)).round.tasks
  end

  # def reload_round(id) do
  #   case Registry.lookup(PokerPlan.RoundRegistry, id) do
  #     [] -> nil
  #     [{pid, nil}] -> Round.reload_round(pid)
  #   end
  # end

  defp refresh_cache({:ok, %PokerPlan.Data.Task{} = task}, _msg) do
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
