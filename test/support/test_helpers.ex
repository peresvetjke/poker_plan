defmodule PokerPlan.TestHelpers do
  alias PokerPlan.Data.{Round, Task, User}
  alias PokerPlan.Repo

  @spec insert_user(list | map) :: any
  def insert_user(attrs \\ %{}) do
    changes =
      attrs
      |> Map.put_new(:name, "Some User")
      |> Map.put_new(:username, "user#{Base.encode16(:crypto.strong_rand_bytes(8))}")
      |> Map.put_new(:password, "supersecret")

    %User{}
    |> User.changeset()
    |> Repo.insert!()
  end

  @spec insert_round(list | map) :: any
  def insert_round(attrs \\ %{}) do
    changes =
      attrs
      |> Map.put_new(:title, "Some Round")

    %Round{}
    |> Round.changeset(changes)
    |> Repo.insert!()
  end

  @spec insert_task(list | map) :: any
  def insert_task(%{round: round} = attrs) do
    changes = attrs |> Map.put_new(:title, "Some task")

    %Task{}
    |> Task.changeset(changes)
    |> Repo.insert!()
  end
end
