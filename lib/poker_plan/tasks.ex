defmodule PokerPlan.Tasks do
  @moduledoc """
  The Tasks context.
  """

  import Ecto.Query, warn: false

  alias PokerPlan.{Repo, Rounds}
  alias PokerPlan.Data.{Round, Task}

  def list_tasks(round_id) do
    Rounds.get_round!(round_id).tasks
  end

  @doc """
  Gets a single task.

  Raises `Ecto.NoResultsError` if the Task does not exist.

  ## Examples

      iex> get_task!(123)
      %Task{}

      iex> get_task!(456)
      ** (Ecto.NoResultsError)

  """
  def get_task!(id), do: Repo.get!(Task, id)
  # def get_task(nil), do: nil

  # def get_task(task_pid) when is_pid(task_pid) do
  #   PokerPlan.Rounds.Task.get(task_pid)
  # end

  @doc """
  Creates a task.

  ## Examples

      iex> create_task(%{field: value})
      {:ok, %Task{}}

      iex> create_task(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_task(attrs \\ %{}) do
    %Task{}
    |> Task.changeset(attrs)
    |> Repo.insert()
    |> refresh(:task_created)
  end

  @doc """
  Updates a task.

  ## Examples

      iex> update_task(task, %{field: new_value})
      {:ok, %Task{}}

      iex> update_task(task, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_task(%Task{} = task, attrs) do
    task
    |> Task.changeset(attrs)
    |> Repo.update()
    |> refresh(:task_updated)
  end

  @doc """
  Deletes a task.

  ## Examples

      iex> delete_task(task)
      {:ok, %Task{}}

      iex> delete_task(task)
      {:error, %Ecto.Changeset{}}

  """
  def delete_task(%Task{} = task) do
    Repo.delete(task)
    |> refresh(:task_deleted)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking task changes.

  ## Examples

      iex> change_task(task)
      %Ecto.Changeset{data: %Task{}}

  """
  def change_task(%Task{} = task, attrs \\ %{}) do
    Task.changeset(task, attrs)
  end

  defp refresh({:ok, task}, msg) do
    case PokerPlan.Rounds.RoundsStore.get(task.round_id) do
      nil ->
        nil

      pid ->
        case msg do
          :task_deleted -> PokerPlan.Rounds.Round.clear_current_task(pid)
          _ -> nil
        end

        PokerPlan.Rounds.Round.reload_round(pid)
    end

    Phoenix.PubSub.broadcast(
      PokerPlan.PubSub,
      "round:#{task.round_id}",
      {msg, task}
    )

    {:ok, task}
  end

  defp refresh({:error, changeset}, _), do: {:error, changeset}

  # defp broadcast({:ok, task}, :task_updated) do
  #   Phoenix.PubSub.broadcast(
  #     PokerPlan.PubSub,
  #     "round:#{task.round_id}",
  #     {:task_updated, task}
  #   )

  #   {:ok, task}
  # end
end
