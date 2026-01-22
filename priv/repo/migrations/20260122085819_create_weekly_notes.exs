defmodule Streaks.Repo.Migrations.CreateWeeklyNotes do
  use Ecto.Migration

  def change do
    create table(:weekly_notes) do
      add :habit_id, references(:habits, on_delete: :delete_all), null: false
      add :year, :integer, null: false
      add :week_number, :integer, null: false
      add :notes, :text

      timestamps(type: :utc_datetime)
    end

    create index(:weekly_notes, [:habit_id])
    create unique_index(:weekly_notes, [:habit_id, :year, :week_number])
  end
end
