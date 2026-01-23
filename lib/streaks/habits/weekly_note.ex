defmodule Streaks.Habits.WeeklyNote do
  use Ecto.Schema
  import Ecto.Changeset

  alias Streaks.Habits.Habit

  @type t :: %__MODULE__{
          id: integer() | nil,
          year: integer() | nil,
          week_number: integer() | nil,
          notes: String.t() | nil,
          habit_id: integer() | nil,
          habit: Habit.t() | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "weekly_notes" do
    field :year, :integer
    field :week_number, :integer
    field :notes, :string

    belongs_to :habit, Habit

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(weekly_note, attrs) do
    weekly_note
    |> cast(attrs, [:year, :week_number, :notes])
    |> validate_required([:year, :week_number])
    |> validate_number(:year, greater_than: 2000, less_than: 3000)
    |> validate_number(:week_number, greater_than_or_equal_to: 1, less_than_or_equal_to: 53)
    |> unique_constraint([:habit_id, :year, :week_number])
  end
end
