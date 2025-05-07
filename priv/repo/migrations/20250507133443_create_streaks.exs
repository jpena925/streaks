defmodule Streaks.Repo.Migrations.CreateStreaks do
  use Ecto.Migration

  def change do
    create table(:streaks) do
      add :name, :string
      add :year, :integer
      add :days, :map
      add :user_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:streaks, [:user_id])
  end
end
