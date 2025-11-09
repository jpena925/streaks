defmodule Streaks.HabitsTest do
  use Streaks.DataCase

  import Streaks.AccountsFixtures
  import Streaks.HabitsFixtures

  alias Streaks.Habits
  alias Streaks.Habits.HabitCompletion

  describe "list_habits/1" do
    test "lists habits for a user" do
      user = user_fixture()
      habit1 = habit_fixture(user, %{name: "Habit 1"})
      habit2 = habit_fixture(user, %{name: "Habit 2"})

      habits = Habits.list_habits(user)

      assert length(habits) == 2
      assert Enum.any?(habits, &(&1.id == habit1.id))
      assert Enum.any?(habits, &(&1.id == habit2.id))
    end

    test "only returns habits for the specified user" do
      user1 = user_fixture()
      user2 = user_fixture()
      _habit1 = habit_fixture(user1, %{name: "User 1 Habit"})
      _habit2 = habit_fixture(user2, %{name: "User 2 Habit"})

      habits = Habits.list_habits(user1)

      assert length(habits) == 1
      assert hd(habits).name == "User 1 Habit"
    end

    test "excludes archived habits" do
      user = user_fixture()
      habit1 = habit_fixture(user, %{name: "Active Habit"})
      habit2 = habit_fixture(user, %{name: "Archived Habit"})

      {:ok, _archived} = Habits.archive_habit(habit2)

      habits = Habits.list_habits(user)

      assert length(habits) == 1
      assert hd(habits).id == habit1.id
    end

    test "orders habits by position" do
      user = user_fixture()
      habit1 = habit_fixture(user, %{name: "First"})
      habit2 = habit_fixture(user, %{name: "Second"})
      habit3 = habit_fixture(user, %{name: "Third"})

      habits = Habits.list_habits(user)

      assert Enum.map(habits, & &1.id) == [habit1.id, habit2.id, habit3.id]
      assert Enum.map(habits, & &1.position) == [1, 2, 3]
    end

    test "preloads completions from the last 365 days only" do
      user = user_fixture()
      habit = habit_fixture(user)

      recent_date = Date.utc_today()
      {:ok, _} = Habits.log_habit_completion(habit, recent_date)

      old_date = Date.add(Date.utc_today(), -400)
      {:ok, _} = Habits.log_habit_completion(habit, old_date)

      [loaded_habit] = Habits.list_habits(user)

      assert length(loaded_habit.completions) == 1
      assert hd(loaded_habit.completions).completed_on == recent_date
    end
  end

  describe "get_habit/2" do
    test "gets a habit by id for the specified user" do
      user = user_fixture()
      habit = habit_fixture(user, %{name: "My Habit"})

      fetched_habit = Habits.get_habit(habit.id, user)

      assert fetched_habit.id == habit.id
      assert fetched_habit.name == "My Habit"
    end

    test "returns nil if habit doesn't exist" do
      user = user_fixture()

      assert Habits.get_habit(99999, user) == nil
    end

    test "returns nil if habit belongs to a different user" do
      user1 = user_fixture()
      user2 = user_fixture()
      habit = habit_fixture(user1)

      assert Habits.get_habit(habit.id, user2) == nil
    end

    test "preloads completions" do
      user = user_fixture()
      habit = habit_fixture(user)
      date = Date.utc_today()
      {:ok, _} = Habits.log_habit_completion(habit, date)

      fetched_habit = Habits.get_habit(habit.id, user)

      assert length(fetched_habit.completions) == 1
      assert hd(fetched_habit.completions).completed_on == date
    end
  end

  describe "create_habit/2" do
    test "creates a habit with valid attributes" do
      user = user_fixture()
      attrs = %{name: "New Habit", has_quantity: false}

      {:ok, habit} = Habits.create_habit(user, attrs)

      assert habit.name == "New Habit"
      assert habit.has_quantity == false
      assert habit.user_id == user.id
    end

    test "creates a habit with quantity tracking" do
      user = user_fixture()
      attrs = %{name: "Push-ups", has_quantity: true}

      {:ok, habit} = Habits.create_habit(user, attrs)

      assert habit.has_quantity == true
    end

    test "sets position automatically" do
      user = user_fixture()
      {:ok, habit1} = Habits.create_habit(user, %{name: "First"})
      {:ok, habit2} = Habits.create_habit(user, %{name: "Second"})
      {:ok, habit3} = Habits.create_habit(user, %{name: "Third"})

      assert habit1.position == 1
      assert habit2.position == 2
      assert habit3.position == 3
    end

    test "returns error with invalid attributes" do
      user = user_fixture()
      attrs = %{name: ""}

      {:error, changeset} = Habits.create_habit(user, attrs)

      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "trims whitespace from habit name" do
      user = user_fixture()
      attrs = %{name: "  Habit Name  "}

      {:ok, habit} = Habits.create_habit(user, attrs)

      assert habit.name == "Habit Name"
    end

    test "rejects habit name longer than 100 characters" do
      user = user_fixture()
      long_name = String.duplicate("a", 101)
      attrs = %{name: long_name}

      {:error, changeset} = Habits.create_habit(user, attrs)

      assert %{name: ["should be at most 100 character(s)"]} = errors_on(changeset)
    end
  end

  describe "update_habit/2" do
    test "updates a habit with valid attributes" do
      user = user_fixture()
      habit = habit_fixture(user, %{name: "Old Name"})

      {:ok, updated_habit} = Habits.update_habit(habit, %{name: "New Name"})

      assert updated_habit.name == "New Name"
    end

    test "returns error with invalid attributes" do
      user = user_fixture()
      habit = habit_fixture(user)

      {:error, changeset} = Habits.update_habit(habit, %{name: ""})

      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "delete_habit/1" do
    test "deletes a habit" do
      user = user_fixture()
      habit = habit_fixture(user)

      {:ok, _deleted_habit} = Habits.delete_habit(habit)

      assert Habits.get_habit(habit.id, user) == nil
    end

    test "deletes habit completions when habit is deleted" do
      user = user_fixture()
      habit = habit_fixture(user)
      date = Date.utc_today()
      {:ok, completion} = Habits.log_habit_completion(habit, date)

      {:ok, _deleted_habit} = Habits.delete_habit(habit)

      assert Repo.get(HabitCompletion, completion.id) == nil
    end
  end

  describe "archive_habit/1" do
    test "archives a habit (soft delete)" do
      user = user_fixture()
      habit = habit_fixture(user)

      {:ok, archived_habit} = Habits.archive_habit(habit)

      assert archived_habit.archived_at != nil
      refute archived_habit in Habits.list_habits(user)
    end

    test "archived habits don't appear in list" do
      user = user_fixture()
      habit1 = habit_fixture(user, %{name: "Active"})
      habit2 = habit_fixture(user, %{name: "To Archive"})

      {:ok, _} = Habits.archive_habit(habit2)

      habits = Habits.list_habits(user)
      assert length(habits) == 1
      assert hd(habits).id == habit1.id
    end
  end

  describe "log_habit_completion/3" do
    test "logs a completion for a date" do
      user = user_fixture()
      habit = habit_fixture(user)
      date = Date.utc_today()

      {:ok, completion} = Habits.log_habit_completion(habit, date)

      assert completion.habit_id == habit.id
      assert completion.completed_on == date
      assert completion.quantity == nil
    end

    test "logs a completion with quantity" do
      user = user_fixture()
      habit = habit_with_quantity_fixture(user)
      date = Date.utc_today()

      {:ok, completion} = Habits.log_habit_completion(habit, date, 25)

      assert completion.quantity == 25
    end

    test "accepts date as string and parses it" do
      user = user_fixture()
      habit = habit_fixture(user)
      date_string = "2024-01-15"

      {:ok, completion} = Habits.log_habit_completion(habit, date_string)

      assert completion.completed_on == ~D[2024-01-15]
    end

    test "returns error with invalid date string" do
      user = user_fixture()
      habit = habit_fixture(user)

      {:error, :invalid_date} = Habits.log_habit_completion(habit, "not-a-date")
    end

    test "upserts on duplicate date (updates quantity)" do
      user = user_fixture()
      habit = habit_with_quantity_fixture(user)
      date = Date.utc_today()

      {:ok, completion1} = Habits.log_habit_completion(habit, date, 10)
      {:ok, completion2} = Habits.log_habit_completion(habit, date, 20)

      assert completion1.id == completion2.id
      assert completion2.quantity == 20
    end

    test "validates quantity is positive" do
      user = user_fixture()
      habit = habit_with_quantity_fixture(user)
      date = Date.utc_today()

      {:error, changeset} = Habits.log_habit_completion(habit, date, 0)
      assert %{quantity: ["must be greater than 0"]} = errors_on(changeset)

      {:error, changeset} = Habits.log_habit_completion(habit, date, -5)
      assert %{quantity: ["must be greater than 0"]} = errors_on(changeset)
    end

    test "allows nil quantity for non-quantity habits" do
      user = user_fixture()
      habit = habit_fixture(user)
      date = Date.utc_today()

      {:ok, completion} = Habits.log_habit_completion(habit, date, nil)

      assert completion.quantity == nil
    end
  end

  describe "unlog_habit_completion/2" do
    test "removes a completion for a date" do
      user = user_fixture()
      habit = habit_fixture(user)
      date = Date.utc_today()
      {:ok, _completion} = Habits.log_habit_completion(habit, date)

      :ok = Habits.unlog_habit_completion(habit, date)

      updated_habit = Habits.get_habit(habit.id, user)
      assert updated_habit.completions == []
    end

    test "accepts date as string" do
      user = user_fixture()
      habit = habit_fixture(user)
      date = Date.utc_today()
      date_string = Date.to_iso8601(date)
      {:ok, _completion} = Habits.log_habit_completion(habit, date)

      :ok = Habits.unlog_habit_completion(habit, date_string)

      updated_habit = Habits.get_habit(habit.id, user)
      assert updated_habit.completions == []
    end

    test "returns error with invalid date string" do
      user = user_fixture()
      habit = habit_fixture(user)

      {:error, :invalid_date} = Habits.unlog_habit_completion(habit, "invalid")
    end
  end

  describe "calculate_streaks/2" do
    test "calculates current streak when completed today" do
      user = user_fixture()
      today = Date.utc_today()
      yesterday = Date.add(today, -1)
      two_days_ago = Date.add(today, -2)
      habit = habit_with_completions_fixture(user, [two_days_ago, yesterday, today])

      streaks = Habits.calculate_streaks(habit, "UTC")

      assert streaks.current_streak == 3
      assert streaks.longest_streak == 3
    end

    test "current streak is 0 if last completion was more than 1 day ago" do
      user = user_fixture()
      today = Date.utc_today()
      three_days_ago = Date.add(today, -3)
      habit = habit_with_completions_fixture(user, [three_days_ago])

      streaks = Habits.calculate_streaks(habit, "UTC")

      assert streaks.current_streak == 0
    end

    test "calculates longest streak correctly" do
      user = user_fixture()
      today = Date.utc_today()

      dates = [
        Date.add(today, -10),
        Date.add(today, -9),
        Date.add(today, -8),
        Date.add(today, -7),
        Date.add(today, -6),
        # gap
        Date.add(today, -4),
        Date.add(today, -3),
        Date.add(today, -2)
      ]

      habit = habit_with_completions_fixture(user, dates)

      streaks = Habits.calculate_streaks(habit, "UTC")

      assert streaks.longest_streak == 5
      assert streaks.current_streak == 0
    end

    test "handles empty completions" do
      user = user_fixture()
      habit = habit_fixture(user)

      streaks = Habits.calculate_streaks(habit, "UTC")

      assert streaks.current_streak == 0
      assert streaks.longest_streak == 0
    end

    test "handles single completion" do
      user = user_fixture()
      today = Date.utc_today()
      habit = habit_with_completions_fixture(user, [today])

      streaks = Habits.calculate_streaks(habit, "UTC")

      assert streaks.current_streak == 1
      assert streaks.longest_streak == 1
    end
  end

  describe "reorder_habits/2" do
    test "reorders habits successfully" do
      user = user_fixture()
      habit1 = habit_fixture(user)
      habit2 = habit_fixture(user)
      habit3 = habit_fixture(user)

      new_order = [habit3.id, habit1.id, habit2.id]
      {:ok, _habits} = Habits.reorder_habits(user, new_order)

      habits = Habits.list_habits(user)
      assert Enum.map(habits, & &1.id) == new_order
      assert Enum.at(habits, 0).position == 1
      assert Enum.at(habits, 1).position == 2
      assert Enum.at(habits, 2).position == 3
    end

    test "rejects reordering with invalid habit IDs" do
      user = user_fixture()
      habit1 = habit_fixture(user)

      {:error, :invalid_habits} = Habits.reorder_habits(user, [habit1.id, 99999])

      # Original order should be preserved
      habits = Habits.list_habits(user)
      assert hd(habits).id == habit1.id
      assert hd(habits).position == 1
    end

    test "only allows reordering user's own habits" do
      user1 = user_fixture()
      user2 = user_fixture()
      habit1 = habit_fixture(user1)
      habit2 = habit_fixture(user2)

      {:error, :invalid_habits} = Habits.reorder_habits(user1, [habit1.id, habit2.id])
    end

    test "excludes archived habits from reordering" do
      user = user_fixture()
      habit1 = habit_fixture(user)
      habit2 = habit_fixture(user)
      {:ok, _archived} = Habits.archive_habit(habit2)

      {:error, :invalid_habits} = Habits.reorder_habits(user, [habit1.id, habit2.id])
    end
  end

  describe "get_completion/2" do
    test "gets a completion for a specific date" do
      user = user_fixture()
      habit = habit_fixture(user)
      date = Date.utc_today()
      {:ok, completion} = Habits.log_habit_completion(habit, date)

      fetched_completion = Habits.get_completion(habit, date)

      assert fetched_completion.id == completion.id
    end

    test "returns nil if no completion for date" do
      user = user_fixture()
      habit = habit_fixture(user)
      date = Date.utc_today()

      assert Habits.get_completion(habit, date) == nil
    end

    test "accepts date as string" do
      user = user_fixture()
      habit = habit_fixture(user)
      date = Date.utc_today()
      {:ok, completion} = Habits.log_habit_completion(habit, date)

      fetched_completion = Habits.get_completion(habit, Date.to_iso8601(date))

      assert fetched_completion.id == completion.id
    end

    test "returns nil for invalid date string" do
      user = user_fixture()
      habit = habit_fixture(user)

      assert Habits.get_completion(habit, "invalid") == nil
    end
  end
end
