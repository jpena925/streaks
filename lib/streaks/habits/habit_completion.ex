defmodule Streaks.Habits.HabitCompletion do
  use Ecto.Schema
  import Ecto.Changeset

  alias Streaks.Habits.Habit

  schema "habit_completions" do
    field :completed_on, :date
    field :quantity, :integer

    belongs_to :habit, Habit

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(habit_completion, attrs) do
    habit_completion
    |> cast(attrs, [:completed_on, :quantity])
    |> validate_required([:completed_on])
    |> unique_constraint([:habit_id, :completed_on],
      message: "Habit already completed on this date"
    )
  end
end
