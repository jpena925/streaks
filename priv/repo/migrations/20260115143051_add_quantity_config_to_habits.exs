defmodule Streaks.Repo.Migrations.AddQuantityConfigToHabits do
  use Ecto.Migration

  def change do
    alter table(:habits) do
      add :quantity_low, :integer, default: 1
      add :quantity_high, :integer, default: 10
      add :quantity_unit, :string
    end
  end
end
