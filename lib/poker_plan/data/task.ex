defmodule PokerPlan.Data.Task do
  use PokerPlan, :model

  @required_fields ~w(round_id state title)a
  @optional_fields ~w()a

  schema "tasks" do
    field(:title, :string)
    field(:state, :string, default: "idle")

    belongs_to(:round, Round)
    has_many(:estimations, Estimation)

    timestamps()
  end

  def changeset(task, %{} = params \\ %{}) do
    task
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:title)
    |> validate_length(:title, min: 3, max: 100)
    |> assoc_constraint(:round)
    |> cast_assoc(:estimations)
  end
end
