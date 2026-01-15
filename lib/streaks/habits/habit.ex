defmodule Streaks.Habits.Habit do
  use Ecto.Schema
  import Ecto.Changeset

  alias Streaks.Accounts.User
  alias Streaks.Habits.HabitCompletion

  @type t :: %__MODULE__{
          id: integer() | nil,
          name: String.t() | nil,
          has_quantity: boolean(),
          quantity_low: integer() | nil,
          quantity_high: integer() | nil,
          archived_at: DateTime.t() | nil,
          position: integer() | nil,
          user_id: integer() | nil,
          user: User.t() | Ecto.Association.NotLoaded.t(),
          completions: [HabitCompletion.t()] | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "habits" do
    field :name, :string
    field :has_quantity, :boolean, default: false
    field :quantity_low, :integer, default: 1
    field :quantity_high, :integer, default: 10
    field :archived_at, :utc_datetime
    field :position, :integer

    belongs_to :user, User
    has_many :completions, HabitCompletion, on_delete: :delete_all

    timestamps(type: :utc_datetime)
  end

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(habit, attrs) do
    habit
    |> cast(attrs, [
      :name,
      :has_quantity,
      :quantity_low,
      :quantity_high,
      :archived_at,
      :position
    ])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 100)
    |> validate_number(:quantity_low, greater_than: 0)
    |> validate_number(:quantity_high, greater_than: 0)
    |> validate_quantity_range()
    |> trim_name()
  end

  defp validate_quantity_range(changeset) do
    low = get_field(changeset, :quantity_low)
    high = get_field(changeset, :quantity_high)

    if low && high && low >= high do
      add_error(changeset, :quantity_high, "must be greater than low value")
    else
      changeset
    end
  end

  defp trim_name(changeset) do
    case get_change(changeset, :name) do
      nil -> changeset
      name -> put_change(changeset, :name, String.trim(name))
    end
  end
end
