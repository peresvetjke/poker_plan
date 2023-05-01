defmodule PokerPlan.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add(:username, :string)
      add(:email, :string, null: false)
      add(:password_hash, :string)
      add(:is_spectator, :boolean)

      timestamps()
    end

    create(unique_index(:users, [:email]))
  end
end
