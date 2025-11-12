defmodule Streaks.Repo.Migrations.AddCompletedOnIndexToHabitCompletions do
  use Ecto.Migration

  def change do
    create index(:habit_completions, [:completed_on])
  end
end
