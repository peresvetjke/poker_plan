defmodule PokerPlan.Tasks.Task do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tasks" do
    field :title, :string
    field :round_id, :id

    timestamps()
  end

  @doc false
  def changeset(task, attrs) do
    task
    |> cast(attrs, [:title])
    |> validate_required([:title])
  end
end
