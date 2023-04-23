defmodule PokerPlan.Repo.Migrations.CreateTasks do
  use Ecto.Migration

  def change do
    create table(:tasks) do
      add(:state, :string, null: false, default: "idle")
      add(:title, :string)
      add(:round_id, references(:rounds, on_delete: :nothing))

      timestamps()
    end

    create(index(:tasks, [:round_id]))
  end
end
