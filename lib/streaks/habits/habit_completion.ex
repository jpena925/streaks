defmodule Streaks.Habits.HabitCompletion do
  use Ecto.Schema
  import Ecto.Changeset

  alias Streaks.Habits.Habit

  @type t :: %__MODULE__{
          id: integer() | nil,
          completed_on: Date.t() | nil,
          quantity: Decimal.t() | nil,
          qualitative_option_id: String.t() | nil,
          qualitative_color: String.t() | nil,
          habit_id: integer() | nil,
          habit: Habit.t() | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "habit_completions" do
    field :completed_on, :date
    field :quantity, :decimal
    field :qualitative_option_id, :string
    field :qualitative_color, :string

    belongs_to :habit, Habit

    timestamps(type: :utc_datetime)
  end

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(habit_completion, attrs) do
    habit_completion
    |> cast(attrs, [:completed_on, :quantity, :qualitative_option_id, :qualitative_color])
    |> validate_required([:completed_on])
    |> validate_optional_positive_quantity()
    |> unique_constraint([:habit_id, :completed_on],
      message: "Habit already completed on this date"
    )
  end

  defp validate_optional_positive_quantity(changeset) do
    case get_field(changeset, :quantity) do
      nil -> changeset
      _ -> validate_number(changeset, :quantity, greater_than: 0)
    end
  end
end
