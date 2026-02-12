defmodule Streaks.StreakCache do
  @moduledoc """
  GenServer that caches computed streak data (current_streak, longest_streak) per
  user/habit/timezone. State is held in memory in the BEAM; we look up or compute
  on demand and invalidate when a habit is logged or unlogged.

  Educational: this module demonstrates GenServer lifecycle, state, call vs cast.
  """
  use GenServer

  # ---------------------------------------------------------------------------
  # Public API (what other code will call)
  # ---------------------------------------------------------------------------

  @doc """
  Starts the StreakCache GenServer. Called by the application supervisor.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Returns cached streak data for a habit, or computes and caches it on first request.

  Uses a GenServer **call** (synchronous): the caller blocks until the process
  replies with the result. The process looks up the key in state; on miss it
  calls into Habits to get completion dates and compute streaks, stores the
  result, then replies.
  """
  def get_streaks(user_id, habit_id, timezone \\ "UTC") do
    GenServer.call(__MODULE__, {:get, user_id, habit_id, timezone})
  end

  @doc """
  Clears cached streaks for a habit so the next get_streaks recomputes.

  Uses a GenServer **cast** (fire-and-forget): we don't wait for a reply. The
  process removes any cache entries for this user_id + habit_id (all timezones)
  and continues. Call this after log_habit_completion or unlog_habit_completion.
  """
  def invalidate(user_id, habit_id) do
    GenServer.cast(__MODULE__, {:invalidate, user_id, habit_id})
  end

  # ---------------------------------------------------------------------------
  # GenServer callbacks (run inside the process)
  # ---------------------------------------------------------------------------

  @doc """
  Called once when the process starts. We return the initial state.
  The process will then sit in a loop, passing this state (or an updated
  version) through every handle_call / handle_cast.
  """
  @impl GenServer
  def init(_opts) do
    state = %{}
    {:ok, state}
  end

  # Handle "get streaks" — synchronous request; we must reply with the result.
  # from: who to reply to (the caller). We reply with {:reply, result, new_state}.
  @impl GenServer
  def handle_call({:get, user_id, habit_id, timezone}, _from, state) do
    key = {user_id, habit_id, timezone}

    {streaks, new_state} =
      case Map.get(state, key) do
        nil ->
          dates = Streaks.Habits.get_completion_dates_for_habit(habit_id, timezone)
          streaks = Streaks.Habits.calculate_streaks_from_dates(dates, timezone)
          new_state = Map.put(state, key, streaks)
          {streaks, new_state}

        cached ->
          {cached, state}
      end

    {:reply, streaks, new_state}
  end

  # Handle "invalidate" — asynchronous; no reply. Remove all keys for this user+habit.
  @impl GenServer
  def handle_cast({:invalidate, user_id, habit_id}, state) do
    new_state =
      state
      |> Enum.reject(fn {{u, h, _tz}, _val} -> u == user_id and h == habit_id end)
      |> Map.new()

    {:noreply, new_state}
  end
end
