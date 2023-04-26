defmodule PokerPlan.Rounds do
  @moduledoc """
  The Rounds context.
  """

  import Ecto.Query, warn: false

  alias PokerPlan.Repo
  alias PokerPlan.Data.{Round, User}

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
  def get_round!(id) do
    Round
    |> Repo.get!(id)
    |> Repo.preload(:tasks)

    # case Agent.start_link(
    #        fn -> %{id: id, users: []} end,
    #        name: via(id)
    #      ) do
    #   {:ok, pid} ->
    #     round =
    #       Round
    #       |> Repo.get!(id)
    #       |> Repo.preload(:tasks)

    #     IO.inspect(pid, label: "pid")

    #     Agent.update(pid, fn _ ->
    #       struct(
    #         PokerPlan.Rounds,
    #         round |> Map.from_struct() |> Map.put(:users, [])
    #       )
    #     end)

    #     Agent.get(via(id), & &1)

    #   {:error, {:already_started, _}} ->
    #     Agent.get(via(id), & &1)
    # end
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
  def update_round(%PokerPlan.Data.Round{} = round, attrs) do
    round
    |> Round.changeset(attrs)
    |> Repo.update()
  end

  def update_round(%PokerPlan.Rounds.Round{} = round, attrs) do
    round
    |> PokerPlan.Rounds.Round.to_round()
    |> update_round(attrs)
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
  def change_round(%PokerPlan.Data.Round{} = round, attrs \\ %{}) do
    Round.changeset(round, attrs)
  end

  def change_round(%PokerPlan.Rounds.Round{} = round, attrs) do
    round
    |> PokerPlan.Rounds.Round.to_round()
    |> change_round(attrs)
  end
end
