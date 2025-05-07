defmodule Streaks.Streaks.Streak do
  use Ecto.Schema
  import Ecto.Changeset

  schema "streaks" do
    field :name, :string
    field :year, :integer
    field :days, :map
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(streak, attrs) do
    streak
    |> cast(attrs, [:name, :year, :days])
    |> validate_required([:name, :year])
  end
end
