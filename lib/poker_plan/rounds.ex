defmodule PokerPlan.Rounds do
  @registry PokerPlan.RoundRegistry
  @enforce_keys ~w[id title tasks]a

  defstruct [:id, :title, :tasks, users: []]

  @moduledoc """
  The Rounds context.
  """

  import Ecto.Query, warn: false

  alias PokerPlan.Repo
  alias PokerPlan.Data.{Round, Task, User}

  @doc """
  Returns the list of rounds.

  ## Examples

      iex> list_rounds()
      [%Round{}, ...]

  """
  def list_rounds do
    Repo.all(Round)
  end

  @doc """
  Gets a single round.

  Raises `Ecto.NoResultsError` if the Round does not exist.

  ## Examples

      iex> get_round!(123)
      %Round{}

      iex> get_round!(456)
      ** (Ecto.NoResultsError)

  """
  def get_round!(id) when is_integer(id) do
    case PokerPlan.Rounds.RoundsStore.get(id) do
      nil ->
        round =
          Round
          |> Repo.get!(id)
          |> Repo.preload(:tasks)

        {:ok, pid} = PokerPlan.Rounds.Round.start_link(round)
        PokerPlan.Rounds.RoundsStore.put(id, pid)
        PokerPlan.Rounds.Round.get(pid)

      pid ->
        PokerPlan.Rounds.Round.get(pid)
    end
  end

  @doc """
  Creates a round.

  ## Examples

      iex> create_round(%{field: value})
      {:ok, %Round{}}

      iex> create_round(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_round(attrs \\ %{}) do
    %Round{}
    |> Round.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a round.

  ## Examples

      iex> update_round(round, %{field: new_value})
      {:ok, %Round{}}

      iex> update_round(round, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_round(%Round{} = round, attrs) do
    round
    |> Round.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a round.

  ## Examples

      iex> delete_round(round)
      {:ok, %Round{}}

      iex> delete_round(round)
      {:error, %Ecto.Changeset{}}

  """
  def delete_round(%Round{} = round) do
    Repo.delete(round)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking round changes.

  ## Examples

      iex> change_round(round)
      %Ecto.Changeset{data: %Round{}}

  """
  def change_round(%Round{} = round, attrs \\ %{}) do
    Round.changeset(round, attrs)
  end

  def add_user(%Round{id: id} = round, %User{} = user) when is_integer(id) do
    pid =
      case PokerPlan.Rounds.RoundsStore.get(round.id) do
        nil ->
          {:ok, pid} = PokerPlan.Rounds.Round.start_link(round)
          pid

        pid ->
          pid
      end

    PokerPlan.Rounds.Round.add_user(pid, user)

    case PokerPlan.Rounds.Round.get(pid).current_task do
      nil -> nil
      pid -> PokerPlan.Rounds.Task.add_user(pid, user.id)
    end
  end

  def start_task(%Task{} = task) do
    round_pid =
      case PokerPlan.Rounds.RoundsStore.get(task.round_id) do
        nil ->
          round =
            Round
            |> Repo.get!(task.round_id)
            |> Repo.preload(:tasks)

          {:ok, pid} = PokerPlan.Rounds.Round.start_link(round)
          pid

        pid ->
          pid
      end

    # round_info = PokerPlan.Rounds.Round.get(round_pid)

    # case round_info.current_task do
    #   nil ->

    #     task_pid = task_pid

    #   previous_task_pid ->
    #     PokerPlan.Rounds.Task.stop(previous_task_pid)
    #     {:ok, task_pid} = PokerPlan.Rounds.Task.start_link(task)
    #     # task_pid = task_pid
    # end

    PokerPlan.Rounds.Round.set_current_task(round_pid, task)
  end
end
