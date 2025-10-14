defmodule Streaks.Repo.Migrations.AddHasQuantityToHabits do
  use Ecto.Migration

  def change do
    alter table(:habits) do
      add :has_quantity, :boolean, default: false, null: false
    end
  end
end
