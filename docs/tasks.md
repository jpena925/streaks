# Streaks Enhancement Roadmap

A curated list of improvements, learning opportunities, and feature ideas—organized by priority and complexity.


## 🔧 Backend: Learning-Focused Enhancements

These are overkill for a single-user app but great for learning.

### 8. GenServer: Streak Calculator Cache

**The idea:** Instead of recalculating streaks on every page load, maintain a GenServer that:

- Caches calculated streaks per user
- Updates incrementally when habits are logged
- Broadcasts updates via PubSub

```elixir
defmodule Streaks.StreakCache do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def get_streaks(user_id, habit_id) do
    GenServer.call(__MODULE__, {:get, user_id, habit_id})
  end

  def invalidate(user_id, habit_id) do
    GenServer.cast(__MODULE__, {:invalidate, user_id, habit_id})
  end

  # ... callbacks
end
```

**Learning opportunity:** GenServer lifecycle, state management, process architecture.

---

### 9. Phoenix Channels: Real-Time Sync

**Use case:** If you have the app open on phone AND laptop, logging a habit on one device instantly updates the other.

**Implementation:**

1. Create `StreaksChannel` that users join on mount
2. Broadcast habit updates to the channel
3. LiveView subscribes and updates UI

```elixir
# In HabitsLive.Index mount:
if connected?(socket) do
  StreaksWeb.Endpoint.subscribe("user:#{user.id}")
end

# In handle_event("log_day", ...):
StreaksWeb.Endpoint.broadcast("user:#{user.id}", "habit_updated", %{habit_id: id})
```

**Learning opportunity:** Phoenix Channels, PubSub patterns, real-time architectures.

---

### 10. Oban: Background Jobs

**Use cases (even for single user):**

- **Daily streak notifications:** "Don't break your 30-day streak!"
- **Weekly digest emails:** Summary of your week
- **Data cleanup:** Archive old completion data

```elixir
defmodule Streaks.Workers.StreakReminder do
  use Oban.Worker, queue: :notifications

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"user_id" => user_id}}) do
    user = Accounts.get_user!(user_id)
    habits_at_risk = Habits.get_habits_at_risk(user)  # Not logged today, has streak

    if habits_at_risk != [] do
      UserNotifier.deliver_streak_reminder(user, habits_at_risk)
    end

    :ok
  end
end
```

**Learning opportunity:** Job queues, scheduling, error handling, retries.

---

### 11. Presence: Who's Online (for future social features)

**When you add friends:** Show who's currently active.

```elixir
defmodule StreaksWeb.Presence do
  use Phoenix.Presence,
    otp_app: :streaks,
    pubsub_server: Streaks.PubSub
end

# Track user presence:
StreaksWeb.Presence.track(socket, "users:online", user.id, %{
  online_at: DateTime.utc_now(),
  current_streak: best_streak
})
```

---

## 👥 Social Features

### 12. Public Streak Pages

**URL:** `yourapp.com/u/username` or `yourapp.com/s/:share_token`

**Features:**

- Read-only view of someone's habit grid
- Optionally hide habit names (just show grids)
- Shareable link generation

**Implementation:**

```elixir
# Add to users table
add :username, :string  # Optional vanity URL
add :share_token, :string  # Random token for sharing

# New route (in :current_user live_session)
live "/u/:username", PublicProfileLive, :show
live "/s/:token", SharedStreaksLive, :show
```

---

### 13. Accountability Partners

**Features:**

- Invite friends via email
- See each other's streaks
- Get notified when partner breaks streak
- Encourage/poke feature

**Database additions:**

```elixir
create table(:partnerships) do
  add :user_id, references(:users)
  add :partner_id, references(:users)
  add :status, :string  # pending, accepted, declined
  add :notifications_enabled, :boolean, default: true
  timestamps()
end
```

---

## 🏗️ Infrastructure (For Fun/Learning)

### 14. ETS Caching

**What:** In-memory caching without external dependencies (like Redis).

**Use case:** Cache habit data for the current session.

```elixir
defmodule Streaks.Cache do
  use GenServer

  def init(_) do
    table = :ets.new(:streaks_cache, [:set, :public, :named_table])
    {:ok, table}
  end

  def get(key) do
    case :ets.lookup(:streaks_cache, key) do
      [{^key, value, expiry}] when expiry > System.system_time(:second) -> {:ok, value}
      _ -> :miss
    end
  end

  def put(key, value, ttl_seconds \\ 300) do
    expiry = System.system_time(:second) + ttl_seconds
    :ets.insert(:streaks_cache, {key, value, expiry})
  end
end
```

**Learning opportunity:** ETS tables, in-memory data structures, cache invalidation.

---

### 15. Telemetry & Observability

**Add custom telemetry events:**

```elixir
:telemetry.execute(
  [:streaks, :habit, :logged],
  %{count: 1},
  %{user_id: user.id, habit_id: habit.id}
)
```

**Build a simple stats dashboard:**

- Habits logged per day
- Most active times
- Streak milestones reached

**Learning opportunity:** Telemetry, LiveDashboard customization, metrics.

---

### 16. Rate Limiting (for public features)

When you add public pages/API, add rate limiting:

```elixir
# Using Hammer library
case Hammer.check_rate("api:#{ip}", 60_000, 100) do
  {:allow, _count} -> proceed()
  {:deny, _limit} -> send_resp(conn, 429, "Too many requests")
end
```

---

## 🧹 Code Quality & DX

### 17. Extract Calendar Module

Move date/calendar logic to its own module as suggested in existing roadmap.

```elixir
defmodule Streaks.Calendar do
  def today(timezone), do: ...
  def get_habit_days(habit, timezone), do: ...
  def group_days_by_month(days), do: ...
  def week_boundaries(date), do: ...
end
```

---

### 18. Add More Typespecs

Your existing typespecs are good. Add them to:

- All public context functions
- LiveView callbacks
- Component functions

Consider enabling Dialyzer's `--strict` mode.

---

### 19. Property-Based Testing

Use StreamData for testing streak calculations:

```elixir
property "streak calculation is always non-negative" do
  check all dates <- list_of(date_generator()) do
    result = Habits.calculate_streaks_from_dates(dates, "UTC")
    assert result.current_streak >= 0
    assert result.longest_streak >= 0
  end
end
```

---

## 📋 Implementation Order Suggestion

**Week 7-8: Backend Learning**

10. [ ] Implement GenServer streak cache
11. [ ] Add real-time sync with Channels

**Future: Social**

12. [ ] Public profile pages
13. [ ] Share tokens
14. [ ] Accountability partners

---

## ⚡ Optional Enhancement: LiveView Streams

Convert `@habits` list to LiveView streams for even better performance. Currently we use targeted in-memory updates which eliminated the N+1 and full refetch. Streams would take it further by only diffing the changed habit card on the server.

**Current approach (good enough for now):**

- Targeted updates via `update_habit_in_list/3`
- Server still re-renders all habit cards to compute diff
- Works well for < 20 habits

**Streams approach (for learning or scaling):**

```elixir
# In mount:
socket = stream(socket, :habits, habits)

# In handle_event:
socket = stream_insert(socket, :habits, updated_habit)
```

Template changes:

```heex
<!-- Current -->
<HabitCard.habit_card :for={{habit, index} <- Enum.with_index(@habits)} ... />

<!-- With streams -->
<div id="habits-list" phx-update="stream">
  <HabitCard.habit_card :for={{dom_id, habit} <- @streams.habits} id={dom_id} ... />
</div>
```

**Tradeoffs:**

- ✅ Only changed habit re-renders on server
- ✅ Better memory efficiency
- ⚠️ Can't easily get `length(@habits)` or check `@habits == []`
- ⚠️ Reordering requires `stream/4` with `reset: true`
- ⚠️ More abstract mental model

**When to do this:** If you notice sluggishness with 10+ habits, or want to learn streams.

---

## 🎯 Quick Wins (< 1 hour each)

- [ ] Add `touch-action: manipulation` CSS to prevent 300ms tap delay
- [ ] Add loading skeleton for habit cards
- [ ] Keyboard shortcut to mark today's habits (press 1-9)
- [ ] Add total completions count to habit cards
- [ ] Add "Mark all as complete" button for today

---