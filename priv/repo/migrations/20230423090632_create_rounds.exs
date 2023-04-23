defmodule PokerPlan.Repo.Migrations.CreateRounds do
  use Ecto.Migration

  def change do
    create table(:rounds) do
      add(:title, :string, null: false)

      timestamps
    end

    create(unique_index(:rounds, [:title]))
  end
end
