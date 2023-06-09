defmodule PokerPlan.Repo.Migrations.CreateEstimations do
  use Ecto.Migration

  def change do
    create table(:estimations) do
      add :value, :integer
      add :task_id, references(:tasks, on_delete: :delete_all)
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps()
    end

    create unique_index(:estimations, [:task_id, :user_id])
    create index(:estimations, [:task_id])
    create index(:estimations, [:user_id])
  end
end
