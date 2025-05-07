defmodule Streaks.HabitsTest do
  use Streaks.DataCase

  alias Streaks.Habits

  describe "streaks" do
    alias Streaks.Habits.Streak

    import Streaks.HabitsFixtures

    @invalid_attrs %{name: nil, year: nil, days: nil}

    test "list_streaks/0 returns all streaks" do
      streak = streak_fixture()
      assert Habits.list_streaks() == [streak]
    end

    test "get_streak!/1 returns the streak with given id" do
      streak = streak_fixture()
      assert Habits.get_streak!(streak.id) == streak
    end

    test "create_streak/1 with valid data creates a streak" do
      valid_attrs = %{name: "some name", year: 42, days: %{}}

      assert {:ok, %Streak{} = streak} = Habits.create_streak(valid_attrs)
      assert streak.name == "some name"
      assert streak.year == 42
      assert streak.days == %{}
    end

    test "create_streak/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Habits.create_streak(@invalid_attrs)
    end

    test "update_streak/2 with valid data updates the streak" do
      streak = streak_fixture()
      update_attrs = %{name: "some updated name", year: 43, days: %{}}

      assert {:ok, %Streak{} = streak} = Habits.update_streak(streak, update_attrs)
      assert streak.name == "some updated name"
      assert streak.year == 43
      assert streak.days == %{}
    end

    test "update_streak/2 with invalid data returns error changeset" do
      streak = streak_fixture()
      assert {:error, %Ecto.Changeset{}} = Habits.update_streak(streak, @invalid_attrs)
      assert streak == Habits.get_streak!(streak.id)
    end

    test "delete_streak/1 deletes the streak" do
      streak = streak_fixture()
      assert {:ok, %Streak{}} = Habits.delete_streak(streak)
      assert_raise Ecto.NoResultsError, fn -> Habits.get_streak!(streak.id) end
    end

    test "change_streak/1 returns a streak changeset" do
      streak = streak_fixture()
      assert %Ecto.Changeset{} = Habits.change_streak(streak)
    end
  end
end
