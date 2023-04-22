defmodule PokerPlan.Repo.Migrations.CreateEstimations do
  use Ecto.Migration

  def change do
    create table(:estimations) do
      add :value, :integer
      add :round_id, references(:rounds, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:estimations, [:round_id])
    create index(:estimations, [:user_id])
  end
end
