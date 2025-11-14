defmodule Streaks.Habits.HabitCompletion do
  use Ecto.Schema
  import Ecto.Changeset

  alias Streaks.Habits.Habit

  @type t :: %__MODULE__{
          id: integer() | nil,
          completed_on: Date.t() | nil,
          quantity: integer() | nil,
          habit_id: integer() | nil,
          habit: Habit.t() | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "habit_completions" do
    field :completed_on, :date
    field :quantity, :integer

    belongs_to :habit, Habit

    timestamps(type: :utc_datetime)
  end

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(habit_completion, attrs) do
    habit_completion
    |> cast(attrs, [:completed_on, :quantity])
    |> validate_required([:completed_on])
    |> validate_number(:quantity, greater_than: 0)
    |> unique_constraint([:habit_id, :completed_on],
      message: "Habit already completed on this date"
    )
  end
end
