defmodule PokerPlan.Data.Round do
  use PokerPlan, :model

  @required_fields ~w(title)a
  @optional_fields ~w()a

  schema "rounds" do
    field(:title, :string)

    has_many(:tasks, Task)

    timestamps()
  end

  def changeset(round, %{} = params \\ %{}) do
    round
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_length(:title, min: 3, max: 20)
    |> unique_constraint(:title)
  end
end
