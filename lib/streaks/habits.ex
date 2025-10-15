defmodule Streaks.Habits do
  @moduledoc """
  The Habits context.
  """

  import Ecto.Query, warn: false
  alias Streaks.Repo

  alias Streaks.Habits.{Habit, HabitCompletion}
  alias Streaks.Accounts.User

  @doc """
  Gets today's date in the specified timezone.
  Defaults to UTC if timezone is invalid.
  """
  def today(timezone \\ "UTC") do
    case DateTime.now(timezone) do
      {:ok, datetime} -> DateTime.to_date(datetime)
      {:error, _} -> Date.utc_today()
    end
  end

  @doc """
  Returns the list of habits for a user.
  """
  def list_habits(%User{id: user_id}) do
    Habit
    |> where([h], h.user_id == ^user_id and is_nil(h.archived_at))
    |> order_by([h], asc: h.inserted_at)
    |> preload(:completions)
    |> Repo.all()
  end

  @doc """
  Gets a single habit.
  Returns nil if not found.
  """
  def get_habit(id, %User{id: user_id}) do
    Habit
    |> where([h], h.id == ^id and h.user_id == ^user_id)
    |> preload(:completions)
    |> Repo.one()
  end

  @doc """
  Gets a single habit.
  Raises if not found.
  """
  def get_habit!(id, %User{id: user_id}) do
    Habit
    |> where([h], h.id == ^id and h.user_id == ^user_id)
    |> preload(:completions)
    |> Repo.one!()
  end

  @doc """
  Creates a habit.
  """
  def create_habit(%User{id: user_id}, attrs \\ %{}) do
    %Habit{user_id: user_id}
    |> Habit.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a habit.
  """
  def update_habit(%Habit{} = habit, attrs) do
    habit
    |> Habit.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a habit.
  """
  def delete_habit(%Habit{} = habit) do
    Repo.delete(habit)
  end

  @doc """
  Archives a habit (soft delete).
  """
  def archive_habit(%Habit{} = habit) do
    update_habit(habit, %{archived_at: DateTime.utc_now()})
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking habit changes.
  """
  def change_habit(%Habit{} = habit, attrs \\ %{}) do
    Habit.changeset(habit, attrs)
  end

  @doc """
  Logs a habit completion for a specific date.
  """
  def log_habit_completion(habit_or_id, date, quantity \\ nil)

  def log_habit_completion(%Habit{id: habit_id}, date, quantity) when is_binary(date) do
    case Date.from_iso8601(date) do
      {:ok, parsed_date} -> log_habit_completion(habit_id, parsed_date, quantity)
      {:error, _} -> {:error, :invalid_date}
    end
  end

  def log_habit_completion(%Habit{id: habit_id}, %Date{} = date, quantity) do
    log_habit_completion(habit_id, date, quantity)
  end

  def log_habit_completion(habit_id, %Date{} = date, quantity) when is_integer(habit_id) do
    attrs = %{completed_on: date}
    attrs = if quantity, do: Map.put(attrs, :quantity, quantity), else: attrs

    %HabitCompletion{habit_id: habit_id}
    |> HabitCompletion.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Removes a habit completion for a specific date.
  """
  def unlog_habit_completion(%Habit{id: habit_id}, date) when is_binary(date) do
    case Date.from_iso8601(date) do
      {:ok, parsed_date} -> unlog_habit_completion(habit_id, parsed_date)
      {:error, _} -> {:error, :invalid_date}
    end
  end

  def unlog_habit_completion(%Habit{id: habit_id}, %Date{} = date) do
    unlog_habit_completion(habit_id, date)
  end

  def unlog_habit_completion(habit_id, %Date{} = date) when is_integer(habit_id) do
    HabitCompletion
    |> where([hc], hc.habit_id == ^habit_id and hc.completed_on == ^date)
    |> Repo.delete_all()

    :ok
  end

  @doc """
  Gets habit completions for the last N days.
  """
  def get_habit_completions(%Habit{id: habit_id}, days \\ 365, timezone \\ "UTC") do
    start_date = Date.add(today(timezone), -days)

    HabitCompletion
    |> where([hc], hc.habit_id == ^habit_id and hc.completed_on >= ^start_date)
    |> order_by([hc], asc: hc.completed_on)
    |> Repo.all()
    |> Enum.map(& &1.completed_on)
  end

  @doc """
  Calculates current and longest streaks for a habit.
  """
  def calculate_streaks(%Habit{} = habit, timezone \\ "UTC") do
    completions = get_habit_completions(habit, 365, timezone)
    calculate_streaks_from_dates(completions, timezone)
  end

  def calculate_streaks_from_dates(completion_dates, timezone \\ "UTC")
      when is_list(completion_dates) do
    todays_date = today(timezone)

    # Sort dates in descending order (most recent first)
    sorted_dates = Enum.sort(completion_dates, Date)

    current_streak = calculate_current_streak(sorted_dates, todays_date)
    longest_streak = calculate_longest_streak(sorted_dates)

    %{current_streak: current_streak, longest_streak: longest_streak}
  end

  defp calculate_current_streak([], _today), do: 0

  defp calculate_current_streak(dates, today) do
    # Check if habit was completed today or yesterday to start counting
    latest_date = List.last(dates)
    days_since_latest = Date.diff(today, latest_date)

    if days_since_latest > 1 do
      0
    else
      count_consecutive_days(Enum.reverse(dates), today, 0)
    end
  end

  defp count_consecutive_days([], _expected_date, count), do: count

  defp count_consecutive_days([date | rest], expected_date, count) do
    if Date.compare(date, expected_date) == :eq do
      next_expected = Date.add(expected_date, -1)
      count_consecutive_days(rest, next_expected, count + 1)
    else
      count
    end
  end

  defp calculate_longest_streak([]), do: 0

  defp calculate_longest_streak(dates) do
    dates
    |> Enum.sort(Date)
    |> find_longest_consecutive_sequence()
  end

  defp find_longest_consecutive_sequence([]), do: 0
  defp find_longest_consecutive_sequence([_single]), do: 1

  defp find_longest_consecutive_sequence(dates) do
    dates
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.reduce({1, 1}, fn [prev, curr], {current_length, max_length} ->
      if Date.diff(curr, prev) == 1 do
        new_length = current_length + 1
        {new_length, max(new_length, max_length)}
      else
        {1, max_length}
      end
    end)
    |> elem(1)
  end

  @doc """
  Gets the last 365 days as a list of dates.
  """
  def get_last_365_days(timezone \\ "UTC") do
    todays_date = today(timezone)

    0..364
    |> Enum.map(&Date.add(todays_date, -&1))
    |> Enum.reverse()
  end

  @doc """
  Gets days aligned to Sunday-Saturday weeks.
  Always starts on a Sunday and shows complete weeks.
  For habits older than 52 weeks, shows the last 52 weeks.
  For newer habits, shows from the Sunday of the creation week forward.
  """
  def get_habit_days(%Habit{inserted_at: inserted_at}, timezone \\ "UTC") do
    todays_date = today(timezone)
    habit_start_date = DateTime.to_date(inserted_at)

    # Find the Sunday of the week containing the habit start date
    # Date.day_of_week returns 1-7 where 1=Monday, 7=Sunday
    habit_day_of_week = Date.day_of_week(habit_start_date)
    days_since_sunday = if habit_day_of_week == 7, do: 0, else: habit_day_of_week
    habit_week_sunday = Date.add(habit_start_date, -days_since_sunday)

    # Find the Sunday of the current week
    today_day_of_week = Date.day_of_week(todays_date)
    days_since_today_sunday = if today_day_of_week == 7, do: 0, else: today_day_of_week
    current_week_sunday = Date.add(todays_date, -days_since_today_sunday)

    # Calculate weeks between habit start and now
    days_since_habit_start = Date.diff(current_week_sunday, habit_week_sunday)
    weeks_since_habit_start = div(days_since_habit_start, 7)

    # Show 52 complete weeks (364 days = 52 weeks * 7 days)
    start_sunday =
      if weeks_since_habit_start >= 52 do
        # Habit is old enough, show last 52 weeks starting from 52 weeks ago
        Date.add(current_week_sunday, -51 * 7)
      else
        # Habit is newer, show from the Sunday of habit creation week
        habit_week_sunday
      end

    # Generate 52 weeks (364 days) starting from start_sunday
    0..363
    |> Enum.map(&Date.add(start_sunday, &1))
  end

  @doc """
  Groups days by month for display purposes.
  Returns a list of tuples with {month_name, column_index} where column_index
  represents which column the month starts in (since grid flows in columns of 7 rows).
  Only includes months that have enough space (at least 4 columns) from the previous label.
  """
  def group_days_by_month(days) do
    days
    |> Enum.with_index()
    |> Enum.reduce([], fn {date, index}, acc ->
      month_key = "#{month_name(date.month)} #{date.year}"
      column_index = div(index, 7)

      # Only add if this is the first occurrence of this month
      if Enum.any?(acc, fn {key, _} -> key == month_key end) do
        acc
      else
        should_add =
          case List.last(acc) do
            nil -> true
            {_, last_column} -> column_index - last_column >= 4
          end

        if should_add do
          acc ++ [{month_key, column_index}]
        else
          acc
        end
      end
    end)
  end

  defp month_name(1), do: "Jan"
  defp month_name(2), do: "Feb"
  defp month_name(3), do: "Mar"
  defp month_name(4), do: "Apr"
  defp month_name(5), do: "May"
  defp month_name(6), do: "Jun"
  defp month_name(7), do: "Jul"
  defp month_name(8), do: "Aug"
  defp month_name(9), do: "Sep"
  defp month_name(10), do: "Oct"
  defp month_name(11), do: "Nov"
  defp month_name(12), do: "Dec"
end
