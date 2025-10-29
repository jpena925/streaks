defmodule Streaks.Repo.Migrations.AddPositionToHabits do
  use Ecto.Migration

  def change do
    alter table(:habits) do
      add :position, :integer
    end

    execute(
      """
      UPDATE habits
      SET position = subquery.row_num
      FROM (
        SELECT id, ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY inserted_at) as row_num
        FROM habits
      ) AS subquery
      WHERE habits.id = subquery.id
      """,
      "UPDATE habits SET position = NULL"
    )

    alter table(:habits) do
      modify :position, :integer, null: false
    end

    create index(:habits, [:user_id, :position])
  end
end
