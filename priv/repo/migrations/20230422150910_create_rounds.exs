defmodule PokerPlan.Repo.Migrations.CreateRounds do
  use Ecto.Migration

  def change do
    create table(:rounds) do
      add :title, :string

      timestamps()
    end
  end
end
