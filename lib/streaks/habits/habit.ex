defmodule Streaks.Habits.Habit do
  use Ecto.Schema
  import Ecto.Changeset

  alias Streaks.Accounts.User
  alias Streaks.Habits.HabitCompletion

  schema "habits" do
    field :name, :string
    field :has_quantity, :boolean, default: false
    field :archived_at, :utc_datetime

    belongs_to :user, User
    has_many :completions, HabitCompletion, on_delete: :delete_all

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(habit, attrs) do
    habit
    |> cast(attrs, [:name, :has_quantity, :archived_at])
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
