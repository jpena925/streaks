defmodule Streaks.Habits do
  @moduledoc """
  The Habits context.
  """

  import Ecto.Query, warn: false
  alias Streaks.Repo

  alias Streaks.Habits.{Habit, HabitCompletion}
  alias Streaks.Accounts.User

  @default_days_back 365
  @max_weeks_display 52
  @min_month_spacing_columns 4

  @doc """
  Gets today's date in the specified timezone.
  Defaults to UTC if timezone is invalid.
  """
  @spec today(String.t()) :: Date.t()
  def today(timezone \\ "UTC") do
    case DateTime.now(timezone) do
      {:ok, datetime} -> DateTime.to_date(datetime)
      {:error, _} -> Date.utc_today()
    end
  end

  @doc """
  Returns the list of habits for a user, ordered by position.
  Only preloads completions from the last 365 days for performance.
  """
  @spec list_habits(User.t()) :: [Habit.t()]
  def list_habits(%User{id: user_id}) do
    Habit
    |> where([h], h.user_id == ^user_id and is_nil(h.archived_at))
    |> order_by([h], asc: h.position)
    |> preload(completions: ^recent_completions_query())
    |> Repo.all()
  end

  @doc """
  Gets a single habit.
  Returns nil if not found.
  Only preloads completions from the last 365 days for performance.
  """
  @spec get_habit(integer(), User.t()) :: Habit.t() | nil
  def get_habit(id, %User{id: user_id}) do
    Habit
    |> where([h], h.id == ^id and h.user_id == ^user_id)
    |> preload(completions: ^recent_completions_query())
    |> Repo.one()
  end

  @doc """
  Gets a single habit.
  Raises if not found.
  Only preloads completions from the last 365 days for performance.
  """
  @spec get_habit!(integer(), User.t()) :: Habit.t()
  def get_habit!(id, %User{id: user_id}) do
    Habit
    |> where([h], h.id == ^id and h.user_id == ^user_id)
    |> preload(completions: ^recent_completions_query())
    |> Repo.one!()
  end

  @doc """
  Creates a habit.
  Automatically sets position to the end of the user's habit list.
  """
  @spec create_habit(User.t(), map()) :: {:ok, Habit.t()} | {:error, Ecto.Changeset.t()}
  def create_habit(%User{id: user_id} = _user, attrs \\ %{}) do
    position = get_next_position(user_id)
    attrs = Map.put(attrs, :position, position)

    %Habit{user_id: user_id}
    |> Habit.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a habit.
  """
  @spec update_habit(Habit.t(), map()) :: {:ok, Habit.t()} | {:error, Ecto.Changeset.t()}
  def update_habit(%Habit{} = habit, attrs) do
    habit
    |> Habit.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a habit.
  """
  @spec delete_habit(Habit.t()) :: {:ok, Habit.t()} | {:error, Ecto.Changeset.t()}
  def delete_habit(%Habit{} = habit) do
    Repo.delete(habit)
  end

  @doc """
  Archives a habit (soft delete).
  """
  @spec archive_habit(Habit.t()) :: {:ok, Habit.t()} | {:error, Ecto.Changeset.t()}
  def archive_habit(%Habit{} = habit) do
    update_habit(habit, %{archived_at: DateTime.utc_now()})
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking habit changes.
  """
  @spec change_habit(Habit.t(), map()) :: Ecto.Changeset.t()
  def change_habit(%Habit{} = habit, attrs \\ %{}) do
    Habit.changeset(habit, attrs)
  end

  @doc """
  Reorders habits based on a list of habit IDs in the desired order.
  """
  @spec reorder_habits(User.t(), [integer()]) :: {:ok, [Habit.t()]} | {:error, term()}
  def reorder_habits(%User{id: user_id}, habit_ids) when is_list(habit_ids) do
    habits =
      Habit
      |> where([h], h.id in ^habit_ids and h.user_id == ^user_id and is_nil(h.archived_at))
      |> Repo.all()

    if length(habits) != length(habit_ids) do
      {:error, :invalid_habits}
    else
      Repo.transaction(fn ->
        now = DateTime.utc_now()

        habit_ids
        |> Enum.with_index(1)
        |> Enum.each(fn {habit_id, position} ->
          from(h in Habit, where: h.id == ^habit_id)
          |> Repo.update_all(set: [position: position, updated_at: now])
        end)

        list_habits(%User{id: user_id})
      end)
    end
  end

  @spec recent_completions_query(integer()) :: Ecto.Query.t()
  defp recent_completions_query(days_back \\ @default_days_back) do
    cutoff_date = Date.add(Date.utc_today(), -days_back)

    from c in HabitCompletion,
      where: c.completed_on >= ^cutoff_date
  end

  @spec get_next_position(integer()) :: integer()
  defp get_next_position(user_id) do
    max_position =
      Habit
      |> where([h], h.user_id == ^user_id and is_nil(h.archived_at))
      |> select([h], max(h.position))
      |> Repo.one()

    if max_position, do: max_position + 1, else: 1
  end

  @doc """
  Logs a habit completion for a specific date.
  """
  @spec log_habit_completion(Habit.t() | integer(), Date.t() | String.t(), integer() | nil) ::
          {:ok, HabitCompletion.t()} | {:error, term()}
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
    |> Repo.insert(
      on_conflict: {:replace, [:quantity, :updated_at]},
      conflict_target: [:habit_id, :completed_on]
    )
  end

  @doc """
  Removes a habit completion for a specific date.
  """
  @spec unlog_habit_completion(Habit.t() | integer(), Date.t() | String.t()) ::
          :ok | {:error, term()}
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
  Gets a single completion for a habit on a specific date.
  Returns nil if not found.
  """
  @spec get_completion(Habit.t(), Date.t() | String.t()) :: HabitCompletion.t() | nil
  def get_completion(%Habit{} = habit, date) when is_binary(date) do
    case Date.from_iso8601(date) do
      {:ok, parsed_date} -> get_completion(habit, parsed_date)
      {:error, _} -> nil
    end
  end

  def get_completion(%Habit{id: habit_id}, %Date{} = date) do
    HabitCompletion
    |> where([hc], hc.habit_id == ^habit_id and hc.completed_on == ^date)
    |> Repo.one()
  end

  @doc """
  Gets habit completions for the last N days.
  """
  @spec get_habit_completions(Habit.t(), integer(), String.t()) :: [Date.t()]
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
  @spec calculate_streaks(Habit.t(), String.t()) :: %{
          current_streak: non_neg_integer(),
          longest_streak: non_neg_integer()
        }
  def calculate_streaks(%Habit{} = habit, timezone \\ "UTC") do
    completions = get_habit_completions(habit, 365, timezone)
    calculate_streaks_from_dates(completions, timezone)
  end

  @spec calculate_streaks_from_dates([Date.t()], String.t()) :: %{
          current_streak: non_neg_integer(),
          longest_streak: non_neg_integer()
        }
  def calculate_streaks_from_dates(completion_dates, timezone \\ "UTC")
      when is_list(completion_dates) do
    todays_date = today(timezone)

    sorted_dates = Enum.sort(completion_dates, Date)

    current_streak = calculate_current_streak(sorted_dates, todays_date)
    longest_streak = calculate_longest_streak(sorted_dates)

    %{current_streak: current_streak, longest_streak: longest_streak}
  end

  @spec calculate_current_streak([Date.t()], Date.t()) :: non_neg_integer()
  defp calculate_current_streak([], _today), do: 0

  defp calculate_current_streak(dates, today) do
    latest_date = List.last(dates)
    days_since_latest = Date.diff(today, latest_date)

    if days_since_latest > 1 do
      0
    else
      count_consecutive_days(Enum.reverse(dates), today, 0)
    end
  end

  @spec count_consecutive_days([Date.t()], Date.t(), non_neg_integer()) :: non_neg_integer()
  defp count_consecutive_days([], _expected_date, count), do: count

  defp count_consecutive_days([date | rest], expected_date, count) do
    if Date.compare(date, expected_date) == :eq do
      next_expected = Date.add(expected_date, -1)
      count_consecutive_days(rest, next_expected, count + 1)
    else
      count
    end
  end

  @spec calculate_longest_streak([Date.t()]) :: non_neg_integer()
  defp calculate_longest_streak([]), do: 0

  defp calculate_longest_streak(dates) do
    dates
    |> Enum.sort(Date)
    |> find_longest_consecutive_sequence()
  end

  @spec find_longest_consecutive_sequence([Date.t()]) :: non_neg_integer()
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
  @spec get_last_365_days(String.t()) :: [Date.t()]
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
  @spec get_habit_days(Habit.t(), String.t()) :: [Date.t()]
  def get_habit_days(%Habit{inserted_at: inserted_at}, timezone \\ "UTC") do
    todays_date = today(timezone)
    habit_start_date = DateTime.to_date(inserted_at)

    # Find the Sunday of the week containing the habit start date
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

    start_sunday =
      if weeks_since_habit_start >= @max_weeks_display do
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
  @spec group_days_by_month([Date.t()]) :: [{String.t(), non_neg_integer()}]
  def group_days_by_month(days) do
    days
    |> Enum.with_index()
    |> Enum.reduce([], fn {date, index}, acc ->
      month_key = "#{month_name(date.month)} #{date.year}"
      column_index = div(index, 7)

      if Enum.any?(acc, fn {key, _} -> key == month_key end) do
        acc
      else
        should_add =
          case List.last(acc) do
            nil -> true
            {_, last_column} -> column_index - last_column >= @min_month_spacing_columns
          end

        if should_add do
          acc ++ [{month_key, column_index}]
        else
          acc
        end
      end
    end)
  end

  @spec month_name(1..12) :: String.t()
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
