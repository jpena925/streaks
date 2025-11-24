defmodule StreaksWeb.HabitsLive.IndexTest do
  use StreaksWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Streaks.AccountsFixtures
  import Streaks.HabitsFixtures

  alias Streaks.Habits

  describe "mount and authentication" do
    test "redirects if user is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/streaks")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log-in"
      assert %{"error" => "You must log in to access this page."} = flash
    end

    test "renders habits index page for authenticated user", %{conn: conn} do
      user = user_fixture()

      {:ok, _lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/streaks")

      assert html =~ "Your Streaks"
      assert html =~ "Add Habit"
    end

    test "loads user's habits on mount", %{conn: conn} do
      user = user_fixture()
      _habit1 = habit_fixture(user, %{name: "Morning Run"})
      _habit2 = habit_fixture(user, %{name: "Read Books"})

      {:ok, _lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/streaks")

      assert html =~ "Morning Run"
      assert html =~ "Read Books"
    end

    test "only shows habits for the current user", %{conn: conn} do
      user1 = user_fixture()
      user2 = user_fixture()

      _habit1 = habit_fixture(user1, %{name: "User 1 Habit"})
      _habit2 = habit_fixture(user2, %{name: "User 2 Habit"})

      {:ok, _lv, html} =
        conn
        |> log_in_user(user1)
        |> live(~p"/streaks")

      assert html =~ "User 1 Habit"
      refute html =~ "User 2 Habit"
    end
  end

  describe "new habit form" do
    setup %{conn: conn} do
      user = user_fixture()
      %{conn: log_in_user(conn, user), user: user}
    end

    test "shows new habit form when button is clicked", %{conn: conn} do
      {:ok, lv, html} = live(conn, ~p"/streaks")

      refute html =~ "Create New Habit"

      html = lv |> element("button", "Add Habit") |> render_click()

      assert html =~ "Create New Habit"
    end

    test "hides new habit form when cancel is clicked", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/streaks")

      html = lv |> element("button", "Add Habit") |> render_click()
      assert html =~ "Create New Habit"

      html = lv |> element("button[phx-click='hide_new_habit_form']") |> render_click()
      refute html =~ "Create New Habit"
    end

    test "shows validation errors in real-time", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/streaks")

      lv |> element("button", "Add Habit") |> render_click()

      # Try to submit empty name
      html =
        lv
        |> form("form[phx-submit='create_habit']", %{
          "habit" => %{"name" => "", "has_quantity" => "false"}
        })
        |> render_change()

      assert html =~ "can&#39;t be blank"
    end

    test "shows validation error for name that's too long", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/streaks")

      lv |> element("button", "Add Habit") |> render_click()

      # Try to submit name that's too long (over 100 characters)
      long_name = String.duplicate("a", 101)

      html =
        lv
        |> form("form[phx-submit='create_habit']", %{
          "habit" => %{"name" => long_name, "has_quantity" => "false"}
        })
        |> render_change()

      assert html =~ "should be at most 100 character"
    end
  end

  describe "create habit" do
    setup %{conn: conn} do
      user = user_fixture()
      %{conn: log_in_user(conn, user), user: user}
    end

    test "creates a new habit successfully", %{conn: conn, user: user} do
      {:ok, lv, _html} = live(conn, ~p"/streaks")

      lv |> element("button", "Add Habit") |> render_click()

      html =
        lv
        |> form("form[phx-submit='create_habit']", %{
          "habit" => %{"name" => "Daily Exercise", "has_quantity" => "false"}
        })
        |> render_submit()

      habits = Habits.list_habits(user)
      assert length(habits) == 1
      assert hd(habits).name == "Daily Exercise"
      refute hd(habits).has_quantity

      refute html =~ "Create New Habit"
      assert html =~ "Daily Exercise"
    end

    test "creates a habit with quantity tracking", %{conn: conn, user: user} do
      {:ok, lv, _html} = live(conn, ~p"/streaks")

      lv |> element("button", "Add Habit") |> render_click()

      lv
      |> form("form[phx-submit='create_habit']", %{
        "habit" => %{"name" => "Push-ups", "has_quantity" => "true"}
      })
      |> render_submit()

      habits = Habits.list_habits(user)
      assert length(habits) == 1
      assert hd(habits).name == "Push-ups"
      assert hd(habits).has_quantity
    end

    test "shows error when habit name is empty", %{conn: conn, user: user} do
      {:ok, lv, _html} = live(conn, ~p"/streaks")

      lv |> element("button", "Add Habit") |> render_click()

      html =
        lv
        |> form("form[phx-submit='create_habit']", %{
          "habit" => %{"name" => "", "has_quantity" => "false"}
        })
        |> render_submit()

      habits = Habits.list_habits(user)
      assert length(habits) == 0

      assert html =~ "Create New Habit"
    end
  end

  describe "delete habit" do
    setup %{conn: conn} do
      user = user_fixture()
      habit = habit_fixture(user, %{name: "To Delete"})
      %{conn: log_in_user(conn, user), user: user, habit: habit}
    end

    test "deletes a habit successfully", %{conn: conn, user: user, habit: habit} do
      {:ok, lv, _html} = live(conn, ~p"/streaks")

      html =
        lv
        |> element("button[phx-click='delete_habit'][phx-value-id='#{habit.id}']")
        |> render_click()

      assert Habits.get_habit(habit.id, user) == nil

      refute html =~ "To Delete"
      assert html =~ "No habits yet"
    end
  end

  describe "log habit completion" do
    setup %{conn: conn} do
      user = user_fixture()
      habit = habit_fixture(user, %{name: "Daily Habit"})
      %{conn: log_in_user(conn, user), user: user, habit: habit}
    end

    test "logs a completion for a habit without quantity", %{conn: conn, user: user, habit: habit} do
      {:ok, lv, _html} = live(conn, ~p"/streaks")

      date = Date.utc_today() |> Date.to_iso8601()

      lv
      |> element(
        "div[phx-click='log_day'][phx-value-habit_id='#{habit.id}'][phx-value-date='#{date}']"
      )
      |> render_click()

      updated_habit = Habits.get_habit(habit.id, user)
      assert length(updated_habit.completions) == 1
    end

    test "opens quantity modal for habit with quantity", %{conn: conn, user: user} do
      habit = habit_with_quantity_fixture(user, %{name: "Push-ups"})
      {:ok, lv, _html} = live(conn, ~p"/streaks")

      date = Date.utc_today() |> Date.to_iso8601()

      html =
        lv
        |> element(
          "div[phx-click='log_day'][phx-value-habit_id='#{habit.id}'][phx-value-date='#{date}']"
        )
        |> render_click()

      assert html =~ "Enter Quantity"
      assert html =~ "Save"
    end
  end

  describe "unlog habit completion" do
    setup %{conn: conn} do
      user = user_fixture()
      date = Date.utc_today()
      habit = habit_with_completions_fixture(user, [date])
      %{conn: log_in_user(conn, user), user: user, habit: habit, date: date}
    end

    test "removes a completion", %{conn: conn, user: user, habit: habit, date: date} do
      {:ok, lv, _html} = live(conn, ~p"/streaks")

      assert length(habit.completions) == 1

      date_str = Date.to_iso8601(date)

      lv
      |> element(
        "div[phx-click='unlog_day'][phx-value-habit_id='#{habit.id}'][phx-value-date='#{date_str}']"
      )
      |> render_click()

      updated_habit = Habits.get_habit(habit.id, user)
      assert length(updated_habit.completions) == 0
    end
  end

  describe "quantity modal" do
    setup %{conn: conn} do
      user = user_fixture()
      habit = habit_with_quantity_fixture(user, %{name: "Push-ups"})
      %{conn: log_in_user(conn, user), user: user, habit: habit}
    end

    test "closes quantity modal", %{conn: conn, habit: habit} do
      {:ok, lv, _html} = live(conn, ~p"/streaks")

      date = Date.utc_today() |> Date.to_iso8601()

      html =
        lv
        |> element(
          "div[phx-click='log_day'][phx-value-habit_id='#{habit.id}'][phx-value-date='#{date}']"
        )
        |> render_click()

      assert html =~ "Enter Quantity"

      html =
        lv
        |> element("button[phx-click='close_quantity_modal']")
        |> render_click()

      refute html =~ "Enter Quantity"
    end

    test "submits valid quantity", %{conn: conn, user: user, habit: habit} do
      {:ok, lv, _html} = live(conn, ~p"/streaks")

      date = Date.utc_today() |> Date.to_iso8601()

      lv
      |> element(
        "div[phx-click='log_day'][phx-value-habit_id='#{habit.id}'][phx-value-date='#{date}']"
      )
      |> render_click()

      html =
        lv
        |> form("form[phx-submit='submit_quantity']", %{"quantity" => "25"})
        |> render_submit()

      updated_habit = Habits.get_habit(habit.id, user)
      assert length(updated_habit.completions) == 1
      assert hd(updated_habit.completions).quantity == 25

      refute html =~ "Enter Quantity"
    end

    test "rejects invalid quantity (non-positive)", %{conn: conn, user: user, habit: habit} do
      {:ok, lv, _html} = live(conn, ~p"/streaks")

      date = Date.utc_today() |> Date.to_iso8601()

      lv
      |> element(
        "div[phx-click='log_day'][phx-value-habit_id='#{habit.id}'][phx-value-date='#{date}']"
      )
      |> render_click()

      html =
        lv
        |> form("form[phx-submit='submit_quantity']", %{"quantity" => "0"})
        |> render_submit()

      updated_habit = Habits.get_habit(habit.id, user)
      assert length(updated_habit.completions) == 0

      assert html =~ "Enter Quantity"
    end

    test "rejects invalid quantity (non-numeric)", %{conn: conn, user: user, habit: habit} do
      {:ok, lv, _html} = live(conn, ~p"/streaks")

      date = Date.utc_today() |> Date.to_iso8601()

      lv
      |> element(
        "div[phx-click='log_day'][phx-value-habit_id='#{habit.id}'][phx-value-date='#{date}']"
      )
      |> render_click()

      html =
        lv
        |> form("form[phx-submit='submit_quantity']", %{"quantity" => "abc"})
        |> render_submit()

      updated_habit = Habits.get_habit(habit.id, user)
      assert length(updated_habit.completions) == 0

      assert html =~ "Enter Quantity"
    end
  end

  describe "habit display" do
    setup %{conn: conn} do
      user = user_fixture()
      %{conn: log_in_user(conn, user), user: user}
    end

    test "displays current streak", %{conn: conn, user: user} do
      today = Date.utc_today()
      yesterday = Date.add(today, -1)
      _habit = habit_with_completions_fixture(user, [yesterday, today])

      {:ok, _lv, html} = live(conn, ~p"/streaks")

      assert html =~ "2 days"
    end

    test "displays longest streak", %{conn: conn, user: user} do
      today = Date.utc_today()
      dates = Enum.map(-4..0, &Date.add(today, &1))
      _habit = habit_with_completions_fixture(user, dates)

      {:ok, _lv, html} = live(conn, ~p"/streaks")

      assert html =~ "Best: 5"
    end

    test "displays habit with quantity completions", %{conn: conn, user: user} do
      today = Date.utc_today()
      completions = [{today, 10}, {Date.add(today, -1), 5}]
      habit = habit_with_quantity_completions_fixture(user, completions)

      {:ok, _lv, html} = live(conn, ~p"/streaks")

      assert html =~ habit.name
    end

    test "displays empty state when no habits exist", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/streaks")

      assert html =~ "No habits yet"
    end

    test "displays multiple habits", %{conn: conn, user: user} do
      _habit1 = habit_fixture(user, %{name: "Habit One"})
      _habit2 = habit_fixture(user, %{name: "Habit Two"})
      _habit3 = habit_fixture(user, %{name: "Habit Three"})

      {:ok, _lv, html} = live(conn, ~p"/streaks")

      assert html =~ "Habit One"
      assert html =~ "Habit Two"
      assert html =~ "Habit Three"
    end
  end

  describe "habit cube component" do
    setup %{conn: conn} do
      user = user_fixture()
      today = Date.utc_today()
      habit = habit_with_completions_fixture(user, [today])
      %{conn: log_in_user(conn, user), user: user, habit: habit, today: today}
    end

    test "renders completed days with correct styling", %{conn: conn, today: today, habit: habit} do
      {:ok, _lv, html} = live(conn, ~p"/streaks")

      assert html =~ "habit-cube-#{habit.id}-#{Date.to_iso8601(today)}"
    end

    test "renders future days as disabled", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/streaks")

      assert html =~ "cursor-not-allowed"
    end
  end

  describe "reorder habits with arrow buttons" do
    setup %{conn: conn} do
      user = user_fixture()
      habit1 = habit_fixture(user, %{name: "First Habit"})
      habit2 = habit_fixture(user, %{name: "Second Habit"})
      habit3 = habit_fixture(user, %{name: "Third Habit"})
      %{conn: log_in_user(conn, user), user: user, habit1: habit1, habit2: habit2, habit3: habit3}
    end

    test "moves habit down successfully", %{
      conn: conn,
      user: user,
      habit1: habit1,
      habit2: habit2,
      habit3: habit3
    } do
      {:ok, lv, _html} = live(conn, ~p"/streaks")

      lv
      |> element("button[phx-click='move_habit_down'][phx-value-id='#{habit1.id}']")
      |> render_click()

      habits = Habits.list_habits(user)
      assert Enum.map(habits, & &1.id) == [habit2.id, habit1.id, habit3.id]
      assert Enum.at(habits, 0).position == 1
      assert Enum.at(habits, 1).position == 2
      assert Enum.at(habits, 2).position == 3
    end

    test "moves habit up successfully", %{
      conn: conn,
      user: user,
      habit1: habit1,
      habit2: habit2,
      habit3: habit3
    } do
      {:ok, lv, _html} = live(conn, ~p"/streaks")

      lv
      |> element("button[phx-click='move_habit_up'][phx-value-id='#{habit3.id}']")
      |> render_click()

      habits = Habits.list_habits(user)
      assert Enum.map(habits, & &1.id) == [habit1.id, habit3.id, habit2.id]
    end

    test "first habit up button is disabled", %{
      conn: conn,
      habit1: habit1
    } do
      {:ok, lv, _html} = live(conn, ~p"/streaks")

      html = render(lv)
      assert html =~ ~s(phx-click="move_habit_up")
      assert html =~ ~s(phx-value-id="#{habit1.id}")
      assert html =~ ~s(disabled)
    end

    test "last habit down button is disabled", %{
      conn: conn,
      habit3: habit3
    } do
      {:ok, lv, _html} = live(conn, ~p"/streaks")

      html = render(lv)
      assert html =~ ~s(phx-click="move_habit_down")
      assert html =~ ~s(phx-value-id="#{habit3.id}")
      assert html =~ ~s(disabled)
    end

    test "reordered habits persist on reload", %{
      conn: conn,
      user: user,
      habit1: habit1,
      habit2: habit2,
      habit3: habit3
    } do
      {:ok, lv, _html} = live(conn, ~p"/streaks")

      lv
      |> element("button[phx-click='move_habit_down'][phx-value-id='#{habit1.id}']")
      |> render_click()

      lv
      |> element("button[phx-click='move_habit_down'][phx-value-id='#{habit1.id}']")
      |> render_click()

      {:ok, _new_lv, _html} = live(conn, ~p"/streaks")

      habits = Habits.list_habits(user)
      assert Enum.map(habits, & &1.id) == [habit2.id, habit3.id, habit1.id]
    end

    test "only shows user's own habits", %{
      conn: conn,
      user: user,
      habit1: habit1,
      habit2: habit2,
      habit3: habit3
    } do
      other_user = user_fixture()
      other_habit = habit_fixture(other_user, %{name: "Other User Habit"})

      {:ok, _lv, html} = live(conn, ~p"/streaks")

      habits = Habits.list_habits(user)
      assert length(habits) == 3
      assert Enum.map(habits, & &1.id) == [habit1.id, habit2.id, habit3.id]

      refute html =~ "Other User Habit"
      refute html =~ ~s(phx-value-id="#{other_habit.id}")

      other_habits = Habits.list_habits(other_user)
      assert hd(other_habits).id == other_habit.id
    end
  end
end
