defmodule Streaks.Repo.Migrations.AddQuantityToHabitCompletions do
  use Ecto.Migration

  def change do
    alter table(:habit_completions) do
      add :quantity, :integer
    end
  end
end
