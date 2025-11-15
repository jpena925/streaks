# Streaks - AI generated improvement Roadmap


### 12. Add Loading States

**Why:** Better UX during async operations.

**Files to modify:**

- `lib/streaks_web/live/habits_live/index.ex`
- `lib/streaks_web/live/habits_live/index.html.heex`

**Pattern:**

```elixir
# Add to mount:
|> assign(:loading, false)

# Wrap expensive operations:
def handle_event("create_habit", params, socket) do
  socket = assign(socket, :loading, true)
  # ... do work ...
  {:noreply, assign(socket, :loading, false)}
end
```

**UI:**

```heex
<div :if={@loading} class="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
  <div class="text-white">Loading...</div>
</div>
```

Or use a spinner component.

---

### 13. Extract Complex Calendar Logic

**Why:** The `get_habit_days` and `group_days_by_month` logic is complex. Would be cleaner in its own module.

**Create new file:**

- `lib/streaks/habits/calendar.ex`

**Move functions:**

- `get_habit_days/2`
- `group_days_by_month/1`
- `month_name/1`
- Helper functions for week calculations

**Keep in Habits context:**

- `get_last_365_days/1` (or move to Calendar)
- `today/1` (or move to Calendar)

---

### 15. Add Documentation to Complex Functions

**Why:** Functions like `calculate_current_streak` and `group_days_by_month` have complex logic.

**Pattern:**

```elixir
@doc """
Calculates the current streak for a habit based on completion dates.

A streak is considered "current" if:
- The habit was completed today, OR
- The habit was completed yesterday (grace period)

The streak counts consecutive days backward from the most recent completion.

## Examples

    iex> calculate_streaks_from_dates([~D[2024-01-01], ~D[2024-01-02], ~D[2024-01-03]], "UTC")
    %{current_streak: 3, longest_streak: 3}

    iex> calculate_streaks_from_dates([~D[2024-01-01]], "UTC")
    %{current_streak: 0, longest_streak: 1}  # Assuming today is much later
"""
```

---

## 🔵 Low Priority (Future Enhancements)

These are nice-to-haves that can wait until the app scales or you have more time.

### 17. Add Background Job for Data Cleanup

**Why:** Eventually completion data might grow large. Clean up old data periodically.

**Add Oban:**

```elixir
{:oban, "~> 2.17"}
```

**Create worker:**

```elixir
defmodule Streaks.Workers.CleanupOldCompletions do
  use Oban.Worker, queue: :maintenance

  @impl Oban.Worker
  def perform(_job) do
    cutoff = Date.add(Date.utc_today(), -730)  # Keep 2 years

    from(c in HabitCompletion, where: c.completed_on < ^cutoff)
    |> Repo.delete_all()

    :ok
  end
end
```

**Note:** Only needed if storage becomes an issue. Current 365-day preload is fine.

---

### 18. Add Habit Categories/Tags

**Why:** Users with many habits might want to organize them.

**Migration:**

```elixir
alter table(:habits) do
  add :category, :string
  add :color, :string
end
```

**UI:**

- Add category filter dropdown
- Color-code habit cards by category

---


### 20. Add Mobile App (React Native / Flutter)

**Why:** Native mobile experience.

**Considerations:**

- Build a JSON API
- Add JWT authentication
- Use Phoenix Channels for real-time updates
- Share business logic through API

---

### 21. Add Social Features

**Why:** Accountability and motivation.

**Features:**

- Share streaks publicly
- Friend system
- Leaderboards
- Challenges

**Note:** Major feature, requires significant architecture changes.

---

### 22. Add Habit Reminders/Notifications

**Why:** Help users build habits with reminders.

**Requirements:**

- Add reminder_time field to habits
- Background job to check reminders
- Email/push notification system
- Timezone-aware scheduling

**Technologies:**

- Oban for scheduling
- Web Push API for browser notifications
- Swoosh/Resend for emails (already have)

