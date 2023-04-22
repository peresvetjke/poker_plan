defmodule PokerPlan.Estimation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "estimations" do
    field :value, :integer
    field :round_id, :id
    field :user_id, :id

    timestamps()
  end

  @doc false
  def changeset(estimation, attrs) do
    estimation
    |> cast(attrs, [:value])
    |> validate_required([:value])
  end
end
