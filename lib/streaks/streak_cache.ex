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
  # We'll add get_streaks/3 and invalidate/2 in the next steps.
  # For now we only start the process.

  @doc """
  Starts the StreakCache GenServer. Called by the application supervisor.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
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
end
