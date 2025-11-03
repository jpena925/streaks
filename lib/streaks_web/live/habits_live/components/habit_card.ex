defmodule StreaksWeb.HabitsLive.HabitCard do
  use StreaksWeb, :html

  alias Streaks.Habits
  alias StreaksWeb.HabitsLive.HabitCube

  attr :habit, :map, required: true
  attr :current_user, :map, required: true
  attr :timezone, :string, required: true

  def habit_card(assigns) do
    completion_dates = get_completion_dates(assigns.habit)
    completions_map = get_completions_map(assigns.habit)
    habit_days = Habits.get_habit_days(assigns.habit, assigns.timezone)
    months = Habits.group_days_by_month(habit_days)
    streaks = Habits.calculate_streaks(assigns.habit, assigns.timezone)
    today = Habits.today(assigns.timezone)

    assigns =
      assigns
      |> assign(:completion_dates, completion_dates)
      |> assign(:completions_map, completions_map)
      |> assign(:habit_days, habit_days)
      |> assign(:months, months)
      |> assign(:streaks, streaks)
      |> assign(:today, today)

    ~H"""
    <.card>
      <!-- Header -->
      <div class="mb-4">
        <!-- Drag handle and editable habit name -->
        <div class="flex items-center gap-2 mb-2">
          <button
            class="drag-handle text-gray-400 hover:text-gray-600 dark:text-gray-600 dark:hover:text-gray-400 cursor-grab active:cursor-grabbing"
            title="Drag to reorder"
          >
            <.icon name="hero-bars-3" class="w-4 h-4" />
          </button>
          <input
            type="text"
            value={@habit.name}
            phx-blur="rename_habit"
            phx-value-id={@habit.id}
            class="text-lg sm:text-xl font-normal text-gray-900 dark:text-white bg-transparent border-none outline-none focus:bg-gray-50 dark:focus:bg-gray-900 focus:px-2 focus:py-1 transition-colors flex-1"
          />
        </div>

    <!-- Stats and Delete Button Row -->
        <div class="flex items-center justify-between gap-2">
          <div class="flex items-center gap-2 flex-wrap">
            <!-- Current streak badge -->
            <.badge
              variant={if(@streaks.current_streak > 0, do: "success", else: "neutral")}
              icon="hero-fire"
              class="font-bold"
            >
              {@streaks.current_streak} day{if @streaks.current_streak != 1, do: "s", else: ""}
            </.badge>

    <!-- Longest streak -->
            <.badge variant="info" icon="hero-sparkles">
              Best: {@streaks.longest_streak}
            </.badge>
          </div>

    <!-- Delete button -->
          <.icon_button
            phx-click="delete_habit"
            phx-value-id={@habit.id}
            data-confirm="Are you sure? This will permanently delete this habit and all its completion data."
            icon="hero-trash"
            title="Delete habit"
          />
        </div>
      </div>

    <!-- Grid container -->
      <div class="border-t border-gray-200 dark:border-gray-800 pt-3 mt-3">
        <!-- Scrollable container for both labels and grid -->
        <div class="overflow-x-auto pb-2">
          <div class="inline-block min-w-full">
            <!-- Month labels -->
            <div class="mb-2 sm:mb-3 text-xs font-medium text-gray-600 dark:text-gray-400">
              <div
                class="grid grid-flow-col gap-1"
                style="grid-template-columns: repeat(53, 14px);"
              >
                <span
                  :for={{month, column_index} <- @months}
                  style={"grid-column-start: #{column_index + 1};"}
                  class="text-center"
                >
                  {String.split(month, " ") |> hd()}
                </span>
              </div>
            </div>

    <!-- Habit completion grid -->
            <div class="grid grid-flow-col grid-rows-7 gap-1 sm:gap-1.5 p-2">
              <HabitCube.habit_cube
                :for={{day, index} <- Enum.with_index(@habit_days)}
                date={day}
                completed={MapSet.member?(@completion_dates, day)}
                quantity={Map.get(@completions_map, day)}
                habit_id={@habit.id}
                is_today={day == @today}
                is_future={Date.compare(day, @today) == :gt}
              />
            </div>
          </div>
        </div>

    <!-- Legend -->
        <div class="mt-3 sm:mt-4 flex flex-wrap items-center gap-3 sm:gap-4 text-xs text-gray-600 dark:text-gray-400">
          <div class="flex items-center gap-1.5 sm:gap-2">
            <div class="w-3 h-3 bg-gray-200 dark:bg-gray-700 rounded-sm"></div>
            <span>No data</span>
          </div>
          <div class="flex items-center gap-1.5 sm:gap-2">
            <div class="w-3 h-3 bg-green-500 rounded-sm"></div>
            <span>Completed</span>
          </div>
          <div class="flex items-center gap-1.5 sm:gap-2">
            <div class="w-3 h-3 bg-gray-100 dark:bg-gray-700 rounded-sm opacity-40"></div>
            <span>Future</span>
          </div>
        </div>
      </div>
    </.card>
    """
  end

  defp get_completion_dates(habit) do
    habit.completions
    |> Enum.map(& &1.completed_on)
    |> MapSet.new()
  end

  defp get_completions_map(habit) do
    habit.completions
    |> Enum.map(&{&1.completed_on, &1.quantity})
    |> Map.new()
  end
end
