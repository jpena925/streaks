defmodule Streaks.Repo.Migrations.CreateHabitCompletions do
  use Ecto.Migration

  def change do
    create table(:habit_completions) do
      add :habit_id, references(:habits, on_delete: :delete_all), null: false
      add :completed_on, :date, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:habit_completions, [:habit_id])
    create unique_index(:habit_completions, [:habit_id, :completed_on])
  end
end
