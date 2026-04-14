defmodule Streaks.Repo.Migrations.TrackingModeAndQualitativeHabits do
  use Ecto.Migration

  def up do
    alter table(:habits) do
      add :tracking_mode, :string, null: false, default: "binary"
      add :qualitative_options, :jsonb, null: false, default: fragment("'[]'::jsonb")
    end

    execute("""
    UPDATE habits SET tracking_mode = 'quantity' WHERE has_quantity = true
    """)

    alter table(:habits) do
      remove :has_quantity
    end

    alter table(:habit_completions) do
      add :qualitative_option_id, :string
      add :qualitative_color, :string
    end
  end

  def down do
    alter table(:habit_completions) do
      remove :qualitative_color
      remove :qualitative_option_id
    end

    alter table(:habits) do
      add :has_quantity, :boolean, null: false, default: false
    end

    execute("""
    UPDATE habits SET has_quantity = true WHERE tracking_mode = 'quantity'
    """)

    alter table(:habits) do
      remove :qualitative_options
      remove :tracking_mode
    end
  end
end
