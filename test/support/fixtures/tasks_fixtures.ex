defmodule PokerPlan.TasksFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `PokerPlan.Tasks` context.
  """

  @doc """
  Generate a task.
  """
  def task_fixture(attrs \\ %{}) do
    {:ok, task} =
      attrs
      |> Enum.into(%{
        title: "some title"
      })
      |> PokerPlan.Tasks.create_task()

    task
  end
end
