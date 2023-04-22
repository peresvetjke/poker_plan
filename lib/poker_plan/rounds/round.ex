defmodule PokerPlan.Rounds.Round do
  use Ecto.Schema
  import Ecto.Changeset

  schema "rounds" do
    field :title, :string

    timestamps()
  end

  @doc false
  def changeset(round, attrs) do
    round
    |> cast(attrs, [:title])
    |> validate_required([:title])
  end
end
