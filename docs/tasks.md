# Streaks Enhancement Roadmap

A curated list of improvements, learning opportunities, and feature ideas—organized by priority and complexity.

---

## 🔴 High Priority: Daily Pain Points

These directly impact your daily experience.

### 1. Edit Quantity Config for Existing Habits

**Problem:** Users can set quantity range (low/high) when creating a habit, but can't edit it for existing habits.

**Solution:** Add an edit modal or settings panel for habits that allows:

- Editing habit name (already works inline)
- Configuring quantity range for quantity habits

**Options:**

- Gear icon on habit card → opens settings modal
- Expand the inline editing to include quantity settings
- Add a "Configure" button that appears for quantity habits

---

### 2. Add "Today Mode" for 7+ Habits (UX)

**Problem:** Scrolling through 7 contribution grids daily is tedious.

**Solution - Compact Dashboard View:**

```
┌─────────────────────────────────────────┐
│  Today - January 8, 2026                │
├─────────────────────────────────────────┤
│  ☐ Exercise          [+]                │
│  ☑ Reading           ✓                  │
│  ☑ Meditation        ✓                  │
│  ☐ Water (3/8)       [+]                │
│  ☑ No Alcohol        ✓                  │
│  ☐ Journal           [+]                │
│  ☐ Code              [+]                │
├─────────────────────────────────────────┤
│  [View Full Grids]                      │
└─────────────────────────────────────────┘
```

**Implementation ideas:**

- Toggle between "Today" and "Grid" view modes
- Today view: single-tap to mark complete
- Swipe gestures for quantity habits
- Show streak count inline ("🔥 12 days")

**Files to create/modify:**

- `lib/streaks_web/live/habits_live/components/today_view.ex` (new)
- `lib/streaks_web/live/habits_live/index.ex` (add view mode toggle)

---

### 3. Weekly Notes with Clickable Week Numbers

**Problem:** The GitHub-style contribution grid shows weeks visually but doesn't provide a way to capture weekly reflections or notes.

**Solution:** Add ISO week numbers at the top of each week column, clickable to open a notes modal.

**Visual mockup:**

```
       3    4    5    6    7   ← Week numbers (clickable)
Mon   ▓▓   ▓▓   ▓▓   ░░   ░░
Tue   ▓▓   ▓▓   ░░   ░░   ░░
Wed   ▓▓   ▓▓   ▓▓   ░░   ░░
Thu   ▓▓   ░░   ▓▓   ░░   ░░
Fri   ▓▓   ▓▓   ▓▓   ░░   ░░
Sat   ░░   ▓▓   ▓▓   ░░   ░░
Sun   ▓▓   ▓▓   ░░   ░░   ░░
```

**Features:**

- Display ISO week number at top of each column (e.g., week 3 = third week of year)
- Click week number → opens modal for that week
- Modal shows: week date range, text area for notes, save/cancel buttons
- Visual indicator if notes exist (e.g., underline, dot, or different color)
- Notes are global per week (not per-habit) for weekly reflections

**Database:**

```elixir
# New migration
create table(:weekly_notes) do
  add :user_id, references(:users, on_delete: :delete_all), null: false
  add :year, :integer, null: false
  add :week_number, :integer, null: false
  add :notes, :text

  timestamps()
end

create unique_index(:weekly_notes, [:user_id, :year, :week_number])
```

**Implementation:**

1. Create `Streaks.Notes` context with `WeeklyNote` schema
2. Add week number row to contribution grid in `habit_card.ex`
3. Create `WeeklyNoteModal` component (similar to existing `QuantityModal`)
4. Use `Date.day_of_week/1` to get ISO week number
5. Pass `weekly_notes` map to components (keyed by `{year, week}`)

**UI considerations:**

- Week numbers should be subtle but visible (smaller font, muted color)
- Hover effect to show clickability
- Weeks with notes could have a small dot indicator or be underlined
- Modal should show week date range (e.g., "Week 3: Jan 13 - Jan 19, 2026")

**Files to create/modify:**

- `priv/repo/migrations/*_create_weekly_notes.exs` (new)
- `lib/streaks/notes/weekly_note.ex` (new schema)
- `lib/streaks/notes.ex` (new context)
- `lib/streaks_web/live/habits_live/components/weekly_note_modal.ex` (new)
- `lib/streaks_web/live/habits_live/components/habit_card.ex` (add week numbers row)
- `lib/streaks_web/live/habits_live/index.ex` (handle modal events, load notes)

---

## 📱 Mobile Experience: PWA

Make Streaks installable on your iPhone home screen.

### 4. Progressive Web App (PWA) Setup

**What you get:**

- Home screen icon (looks like a native app)
- Full-screen experience (no Safari UI)
- Faster loading (service worker caching)
- Works offline (view your streaks, queue updates)

**Step 1: Web App Manifest**

Create `priv/static/manifest.json`:

```json
{
	"name": "Streaks",
	"short_name": "Streaks",
	"description": "Track your habits with style",
	"start_url": "/streaks",
	"display": "standalone",
	"background_color": "#000000",
	"theme_color": "#000000",
	"icons": [
		{
			"src": "/images/icon-192.png",
			"sizes": "192x192",
			"type": "image/png"
		},
		{
			"src": "/images/icon-512.png",
			"sizes": "512x512",
			"type": "image/png"
		}
	]
}
```

**Step 2: Link manifest in root layout**

```heex
<link rel="manifest" href="/manifest.json" />
<meta name="apple-mobile-web-app-capable" content="yes" />
<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent" />
<link rel="apple-touch-icon" href="/images/icon-192.png" />
```

**Step 3: Service Worker (optional but cool)**

Create `priv/static/sw.js` for offline caching. This is where you'd cache the app shell and potentially queue habit updates when offline.

**Learning opportunity:** Service workers, Cache API, offline-first architecture.

**Files to create/modify:**

- `priv/static/manifest.json` (new)
- `priv/static/images/icon-*.png` (new - generate from favicon)
- `lib/streaks_web/components/layouts/root.html.heex`
- `priv/static/sw.js` (optional)

---

### 5. Touch-Optimized Interactions

**Problem:** Small 14px habit cubes are hard to tap on mobile.

**Solutions:**

- Increase cube size on mobile: `w-5 h-5 sm:w-3.5 sm:h-3.5`
- Add haptic feedback via JS: `navigator.vibrate(10)`
- Long-press to edit quantity (instead of modal)
- Swipe gestures for quick actions

**Create a touch hook:**

```javascript
// assets/js/hooks/touch.js
export default {
	mounted() {
		let longPressTimer;

		this.el.addEventListener("touchstart", (e) => {
			longPressTimer = setTimeout(() => {
				this.pushEvent("long_press", { id: this.el.dataset.id });
				navigator.vibrate?.(50);
			}, 500);
		});

		this.el.addEventListener("touchend", () => {
			clearTimeout(longPressTimer);
		});
	},
};
```

---

## 🎨 Retro Terminal Aesthetic

You mentioned loving the terminal/retro vibe. Let's lean into it harder.

### 6. CRT/Retro Visual Effects

**Ideas:**

- Scanline overlay effect (CSS)
- Subtle screen flicker animation
- Phosphor glow on green completion cubes
- ASCII-style borders and decorations
- Blinking cursor on inputs

**CSS additions:**

```css
/* Scanlines */
.crt-overlay {
	pointer-events: none;
	position: fixed;
	inset: 0;
	background: repeating-linear-gradient(
		0deg,
		rgba(0, 0, 0, 0.1) 0px,
		rgba(0, 0, 0, 0.1) 1px,
		transparent 1px,
		transparent 2px
	);
}

/* Phosphor glow */
.habit-complete {
	box-shadow: 0 0 8px rgba(34, 197, 94, 0.6), 0 0 16px rgba(34, 197, 94, 0.3);
}

/* Text glow */
.terminal-text {
	text-shadow: 0 0 5px currentColor;
}
```

**Typography options beyond JetBrains Mono:**

- IBM Plex Mono
- Fira Code
- VT323 (very retro)
- Press Start 2P (pixel font - maybe too much)

---

### 7. ASCII Art & Terminal Decorations

**Header example:**

```
╔══════════════════════════════════════╗
║  STREAKS v0.1.0                      ║
║  USER: jack@example.com              ║
║  UPTIME: 47 days                     ║
╚══════════════════════════════════════╝
```

**Habit card borders:**

```
┌─[ Exercise ]────────────────🔥 12 days─┐
│ ▓▓▓▓░░▓▓▓▓▓▓▓▓░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │
│ ▓▓▓▓▓▓▓▓▓▓░░▓▓▓▓▓▓▓▓░░░░▓▓▓▓▓▓▓▓▓▓▓▓ │
└──────────────────────────────────────────┘
```

**Implementation:** Create box-drawing character components in `core_components.ex`.

---

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

**Week 1-2: Daily Pain Points**

1. [x] ~~Fix slow toggle (targeted updates + N+1 fix)~~ ✅ Done
2. [ ] Add "Today" compact view
3. [ ] Add weekly notes with clickable week numbers

**Week 3-4: Mobile & PWA**

4. [ ] Larger touch targets on mobile
5. [ ] Add manifest.json
6. [ ] Add proper icons
7. [ ] Test "Add to Home Screen" on iPhone

**Week 5-6: Aesthetic**

8. [ ] Add CRT/retro effects (opt-in toggle)
9. [ ] Experiment with ASCII borders

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

## Resources

- [Phoenix LiveView Streams](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#stream/4)
- [PWA on iOS](https://web.dev/learn/pwa/installation/)
- [GenServer Guide](https://elixir-lang.org/getting-started/mix-otp/genserver.html)
- [Phoenix Channels](https://hexdocs.pm/phoenix/channels.html)
- [Oban Documentation](https://hexdocs.pm/oban/Oban.html)
- [Retro CSS Effects](https://aleclownes.com/2017/02/01/crt-display-css.html)
