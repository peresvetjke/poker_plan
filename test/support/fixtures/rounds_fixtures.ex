defmodule PokerPlan.RoundsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `PokerPlan.Rounds` context.
  """

  @doc """
  Generate a round.
  """
  def round_fixture(attrs \\ %{}) do
    {:ok, round} =
      attrs
      |> Enum.into(%{
        title: "some title"
      })
      |> PokerPlan.Rounds.create_round()

    round
  end
end
