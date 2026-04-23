defmodule Streaks.Repo.Migrations.QuantityFieldsToDecimal do
  use Ecto.Migration

  def change do
    alter table(:habits) do
      modify :quantity_low, :decimal, default: 1
      modify :quantity_high, :decimal, default: 10
    end

    alter table(:habit_completions) do
      modify :quantity, :decimal
    end
  end
end
