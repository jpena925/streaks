defmodule Streaks.HabitsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Streaks.Habits` context.
  """

  alias Streaks.Habits

  def habit_fixture(user, attrs \\ %{}) do
    valid_attrs =
      Enum.into(attrs, %{
        name: "Test Habit #{System.unique_integer()}",
        has_quantity: false
      })

    {:ok, habit} = Habits.create_habit(user, valid_attrs)
    habit
  end

  def habit_with_quantity_fixture(user, attrs \\ %{}) do
    habit_fixture(user, Map.put(attrs, :has_quantity, true))
  end

  def habit_with_completions_fixture(user, dates \\ []) do
    habit = habit_fixture(user)

    Enum.each(dates, fn date ->
      {:ok, _completion} = Habits.log_habit_completion(habit, date)
    end)

    Habits.get_habit(habit.id, user)
  end

  def habit_with_quantity_completions_fixture(user, completions \\ []) do
    habit = habit_with_quantity_fixture(user)

    Enum.each(completions, fn {date, quantity} ->
      {:ok, _completion} = Habits.log_habit_completion(habit, date, quantity)
    end)

    Habits.get_habit(habit.id, user)
  end
end
