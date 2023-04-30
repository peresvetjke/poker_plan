defmodule PokerPlan.Data.Estimation do
  use PokerPlan, :model

  @required_fields ~w(value task_id user_id)a
  @optional_fields ~w()a

  schema "estimations" do
    field(:value, :integer)

    belongs_to :task, Task
    belongs_to(:user, User)

    timestamps()
  end

  def changeset(estimation, %{} = params \\ %{}) do
    estimation
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> assoc_constraint(:task)
    |> assoc_constraint(:user)
  end
end
