# Streaks - AI generated improvement Roadmap

---

## 🟡 High Priority (Do Soon)

These improve code quality, maintainability, and user experience.

### 4. Add Context-Level Tests

**Why:** Currently only have LiveView integration tests. Need unit tests for business logic.

**Create file:**

- `test/streaks/habits_test.exs`

**Tests to add:**

```
- describe "list_habits/1"
  - lists habits for user
  - excludes archived habits
  - orders by position
  - only returns user's own habits

- describe "create_habit/2"
  - creates habit with valid attrs
  - rejects invalid attrs
  - sets position automatically
  - handles quantity flag

- describe "delete_habit/1"
  - deletes habit and completions

- describe "archive_habit/1"
  - archives habit (soft delete)
  - archived habits don't appear in list

- describe "log_habit_completion/3"
  - logs completion for date
  - handles quantity
  - upserts on duplicate date
  - validates date format

- describe "calculate_streaks/2"
  - calculates current streak correctly
  - handles today completion
  - handles yesterday completion
  - resets if gap > 1 day
  - calculates longest streak
  - handles timezone edge cases
  - handles empty completions

- describe "get_habit_days/2"
  - returns correct week alignment
  - handles habits older than 52 weeks
  - handles recent habits

- describe "group_days_by_month/1"
  - groups days correctly
  - respects 4-column minimum
  - handles year boundaries
```

### 7. Implement Archive Habit Feature

**Why:** Field exists in DB and schema, but no UI for it. Users may want to hide habits without deleting them.

**Files to modify:**

- `lib/streaks_web/live/habits_live/index.ex`
- `lib/streaks_web/live/habits_live/components/habit_card.ex`

**LiveView changes:**

```elixir
def handle_event("archive_habit", %{"id" => id}, socket) do
  with {:ok, habit} <- fetch_user_habit(id, socket),
       {:ok, _habit} <- Habits.archive_habit(habit) do
    habits = Habits.list_habits(socket.assigns.current_scope.user)

    {:noreply,
     socket
     |> assign(:habits, habits)
     |> put_flash(:info, "Habit archived! (Can't unarchive yet - delete to remove completely)")}
  else
    :error -> {:noreply, habit_not_found(socket)}
    {:error, _} -> {:noreply, put_flash(socket, :error, "Error archiving habit")}
  end
end
```

**UI changes:**
Add an "Archive" button or dropdown menu to habit card with Archive/Delete options.

**Future enhancement:**
Add a "Show Archived" toggle and `unarchive_habit/1` function.

---

## 🟢 Medium Priority (Nice to Have)

These are quality-of-life improvements and optimizations.

### 9. Extract Magic Numbers to Module Attributes

**Why:** Improves maintainability and makes constants easy to change.

**Files to modify:**

- `lib/streaks/habits.ex`

**Changes:**

```elixir
@default_days_back 365
@max_weeks_display 52
@min_month_spacing_columns 4

defp recent_completions_query(days_back \\ @default_days_back) do
  # ...
end

def get_habit_days(%Habit{inserted_at: inserted_at}, timezone \\ "UTC") do
  # Use @max_weeks_display instead of hardcoded 52
end

def group_days_by_month(days) do
  # Use @min_month_spacing_columns instead of hardcoded 4
end
```

---

### 10. Add Credo for Code Quality

**Why:** Automated code quality checks catch common issues.

**Add to mix.exs:**

```elixir
{:credo, "~> 1.7", only: [:dev, :test], runtime: false}
```

**Create `.credo.exs`:**

```elixir
%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ["lib/", "test/"],
        excluded: [~r"/_build/", ~r"/deps/", ~r"/node_modules/"]
      },
      strict: true,
      checks: %{
        enabled: [
          {Credo.Check.Readability.ModuleDoc, false},
        ]
      }
    }
  ]
}
```

**Add to precommit alias:**

```elixir
precommit: [
  "compile --warning-as-errors",
  "deps.unlock --unused",
  "format",
  "credo --strict",  # Add this
  "dialyzer",
  "test"
]
```

---

### 11. Optimize Streak Calculation Caching

**Why:** Streaks are recalculated on every render. Could be memoized.

**Option A:** Calculate once in LiveView mount/handle_event, pass as prop to component
**Option B:** Add a `current_streak` and `longest_streak` field to habits table, update on completion

**For now:** Option A is simpler. Calculate in LiveView, pass to component.

**Files to modify:**

- `lib/streaks_web/live/habits_live/index.ex`
- `lib/streaks_web/live/habits_live/components/habit_card.ex`

**Pattern:**

```elixir
# In LiveView mount or after updating habits:
habits_with_streaks =
  Enum.map(habits, fn habit ->
    streaks = Habits.calculate_streaks(habit, timezone)
    Map.put(habit, :streaks, streaks)
  end)

assign(socket, :habits, habits_with_streaks)
```

Then in component, just use `@habit.streaks`.

---

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

### 14. Add Keyboard Shortcuts

**Why:** Power users appreciate keyboard navigation.

**Shortcuts to add:**

- `n` - New habit
- `Escape` - Close modal/form
- `?` - Show help modal with shortcuts

**Implementation:**
Add a new JS hook for keyboard shortcuts or use LiveView's `phx-window-keydown`.

**Example:**

```heex
<div phx-window-keydown="handle_keydown">
  <!-- content -->
</div>
```

```elixir
def handle_event("handle_keydown", %{"key" => "n"}, socket) do
  {:noreply, assign(socket, :show_new_habit_form, true)}
end

def handle_event("handle_keydown", %{"key" => "Escape"}, socket) do
  {:noreply, reset_new_habit_form(socket)}
end
```

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

### 16. Add Telemetry Events

**Why:** Better observability and debugging in production.

**Files to modify:**

- `lib/streaks/habits.ex`

**Pattern:**

```elixir
def log_habit_completion(habit_id, date, quantity) do
  :telemetry.span(
    [:streaks, :habits, :log_completion],
    %{habit_id: habit_id},
    fn ->
      result = # ... your logic
      {result, %{has_quantity: quantity != nil}}
    end
  )
end
```

**Add handlers in application.ex:**

```elixir
:telemetry.attach_many(
  "streaks-telemetry",
  [
    [:streaks, :habits, :log_completion, :start],
    [:streaks, :habits, :log_completion, :stop]
  ],
  &StreaksWeb.Telemetry.handle_event/4,
  nil
)
```

---

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

### 19. Add Export Feature

**Why:** Users might want to export their data (CSV, JSON).

**Endpoint:**

```elixir
def handle_event("export_data", _params, socket) do
  user = socket.assigns.current_scope.user
  habits = Habits.list_habits(user)

  csv_data = generate_csv(habits)

  {:noreply,
   socket
   |> push_event("download", %{
     filename: "streaks_export_#{Date.utc_today()}.csv",
     data: csv_data
   })}
end
```

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

---

## Summary Checklist

### Critical (Do First)

- [ ] Add database indexes
- [ ] Optimize reorder_habits batch updates

### High Priority (Do Soon)

- [ ] Add typespecs for Dialyzer
- [ ] Improve error messages
- [ ] Implement archive habit UI
- [ ] Add form validation feedback

### Medium Priority (Nice to Have)

- [ ] Extract magic numbers to constants
- [ ] Add Credo for code quality
- [ ] Optimize streak calculation caching
- [ ] Add loading states
- [ ] Extract calendar logic to module
- [ ] Add keyboard shortcuts
- [ ] Add documentation to complex functions

### Low Priority (Future)

- [ ] Add telemetry events
- [ ] Add background job for cleanup
- [ ] Add habit categories/tags
- [ ] Add export feature
- [ ] Add mobile app
- [ ] Add social features
- [ ] Add reminders/notifications

---

## Suggested Order of Execution

1. **Week 1:** Critical items (#1-3)
2. **Week 2:** High priority testing and types (#4-5)
3. **Week 3:** High priority UX improvements (#6-8)
4. **Week 4:** Medium priority quality improvements (#9-11)
5. **Ongoing:** Low priority as needed

