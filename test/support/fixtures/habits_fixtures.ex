defmodule Streaks.HabitsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Streaks.Habits` context.
  """

  @doc """
  Generate a streak.
  """
  def streak_fixture(attrs \\ %{}) do
    {:ok, streak} =
      attrs
      |> Enum.into(%{
        days: %{},
        name: "some name",
        year: 42
      })
      |> Streaks.Habits.create_streak()

    streak
  end
end
