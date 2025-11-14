defmodule Streaks.Habits.Habit do
  use Ecto.Schema
  import Ecto.Changeset

  alias Streaks.Accounts.User
  alias Streaks.Habits.HabitCompletion

  @type t :: %__MODULE__{
          id: integer() | nil,
          name: String.t() | nil,
          has_quantity: boolean(),
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
    field :archived_at, :utc_datetime
    field :position, :integer

    belongs_to :user, User
    has_many :completions, HabitCompletion, on_delete: :delete_all

    timestamps(type: :utc_datetime)
  end

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(habit, attrs) do
    habit
    |> cast(attrs, [:name, :has_quantity, :archived_at, :position])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 100)
    |> trim_name()
  end

  defp trim_name(changeset) do
    case get_change(changeset, :name) do
      nil -> changeset
      name -> put_change(changeset, :name, String.trim(name))
    end
  end
end
