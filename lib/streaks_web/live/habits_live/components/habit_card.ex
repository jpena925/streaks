defmodule StreaksWeb.HabitsLive.HabitCard do
  use StreaksWeb, :html

  alias Streaks.Habits
  alias StreaksWeb.HabitsLive.HabitCube

  attr :habit, :map, required: true
  attr :current_user, :map, required: true
  attr :timezone, :string, required: true
  attr :is_first, :boolean, default: false
  attr :is_last, :boolean, default: false
  attr :weekly_notes_map, :map, default: %{}

  def habit_card(assigns) do
    completion_dates = get_completion_dates(assigns.habit)
    completions_map = get_completions_map(assigns.habit)
    habit_days = Habits.get_habit_days(assigns.habit, assigns.timezone)
    months = Habits.group_days_by_month(habit_days)
    today = Habits.today(assigns.timezone)
    week_numbers = get_week_numbers(habit_days)

    streak_dates = Enum.map(assigns.habit.completions, & &1.completed_on)
    streaks = Habits.calculate_streaks_from_dates(streak_dates, assigns.timezone)

    assigns =
      assigns
      |> assign(:completion_dates, completion_dates)
      |> assign(:completions_map, completions_map)
      |> assign(:habit_days, habit_days)
      |> assign(:months, months)
      |> assign(:week_numbers, week_numbers)
      |> assign(:streaks, streaks)
      |> assign(:today, today)

    ~H"""
    <.card>
      <!-- Header -->
      <div class="mb-4">
        <!-- Reorder buttons and editable habit name -->
        <div class="flex items-center gap-2 mb-2">
          <div class="flex flex-col gap-0.5">
            <button
              phx-click="move_habit_up"
              phx-value-id={@habit.id}
              disabled={@is_first}
              class={[
                "text-gray-400 hover:text-gray-600 dark:text-gray-600 dark:hover:text-gray-400 transition-colors",
                @is_first && "opacity-30 cursor-not-allowed"
              ]}
              title="Move up"
            >
              <.icon name="hero-chevron-up" class="w-4 h-4" />
            </button>
            <button
              phx-click="move_habit_down"
              phx-value-id={@habit.id}
              disabled={@is_last}
              class={[
                "text-gray-400 hover:text-gray-600 dark:text-gray-600 dark:hover:text-gray-400 transition-colors",
                @is_last && "opacity-30 cursor-not-allowed"
              ]}
              title="Move down"
            >
              <.icon name="hero-chevron-down" class="w-4 h-4" />
            </button>
          </div>
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
          
    <!-- Action buttons -->
          <div class="flex items-center gap-1">
            <.icon_button
              phx-click="open_settings_modal"
              phx-value-id={@habit.id}
              icon="hero-cog-6-tooth"
              title="Habit settings"
            />
            <.icon_button
              phx-click="archive_habit"
              phx-value-id={@habit.id}
              data-confirm="Archive this habit? You can restore it later from the archived section."
              icon="hero-archive-box"
              title="Archive habit"
            />
          </div>
        </div>
      </div>
      
    <!-- Grid container -->
      <div class="border-t border-gray-200 dark:border-gray-700 pt-3 mt-3">
        <!-- Scrollable container for both labels and grid -->
        <div class="overflow-x-auto pb-2">
          <div class="inline-block min-w-full">
            <!-- Month labels - uses same grid structure for perfect alignment -->
            <div class="grid grid-flow-col grid-rows-1 gap-1.5 sm:gap-1.5 px-2 mb-1 text-xs font-medium text-gray-600 dark:text-gray-400">
              <div
                :for={col_index <- 0..51}
                class="w-5 sm:w-3.5 whitespace-nowrap overflow-visible"
              >
                {get_month_label_for_column(@months, col_index)}
              </div>
            </div>
            <!-- Week numbers row - clickable for notes -->
            <div class="grid grid-flow-col grid-rows-1 gap-1.5 sm:gap-1.5 px-2 mb-1">
              <button
                :for={{year, week_num, _col_index} <- @week_numbers}
                type="button"
                phx-click="open_weekly_note_modal"
                phx-value-habit_id={@habit.id}
                phx-value-year={year}
                phx-value-week={week_num}
                class={[
                  "w-5 sm:w-3.5 text-[10px] sm:text-[10px] text-center tabular-nums transition-colors cursor-pointer touch-manipulation",
                  "hover:text-green-600 dark:hover:text-green-400",
                  if(Map.has_key?(@weekly_notes_map, {year, week_num}),
                    do: "text-green-600 dark:text-green-400 font-semibold",
                    else: "text-gray-400 dark:text-gray-500"
                  )
                ]}
                title={
                  if Map.has_key?(@weekly_notes_map, {year, week_num}),
                    do: "View/edit note for week #{week_num}",
                    else: "Add note for week #{week_num}"
                }
              >
                {week_num}
              </button>
            </div>
            <!-- Habit completion grid -->
            <div class="grid grid-flow-col grid-rows-7 gap-1.5 sm:gap-1.5 px-2 pb-2">
              <HabitCube.habit_cube
                :for={{day, _index} <- Enum.with_index(@habit_days)}
                date={day}
                completed={MapSet.member?(@completion_dates, day)}
                quantity={Map.get(@completions_map, day)}
                habit_id={@habit.id}
                has_quantity={@habit.has_quantity}
                quantity_low={@habit.quantity_low || 1}
                quantity_high={@habit.quantity_high || 10}
                is_today={day == @today}
                is_future={Date.compare(day, @today) == :gt}
              />
            </div>
          </div>
        </div>
        
    <!-- Legend -->
        <div class="mt-3 sm:mt-4 flex flex-wrap items-center gap-3 sm:gap-4 text-xs text-gray-600 dark:text-gray-300">
          <div class="flex items-center gap-1.5 sm:gap-2">
            <div class="w-3 h-3 bg-gray-200 dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded-sm">
            </div>
            <span>No data</span>
          </div>
          <div class="flex items-center gap-1.5 sm:gap-2">
            <div class="w-3 h-3 bg-green-500 border border-green-600 dark:border-green-400 rounded-sm habit-cube-complete">
            </div>
            <span>Completed</span>
          </div>
          <div class="flex items-center gap-1.5 sm:gap-2">
            <div class="w-3 h-3 bg-gray-100 dark:bg-gray-800/50 border border-gray-200 dark:border-gray-700 rounded-sm opacity-40">
            </div>
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

  defp get_week_numbers(days) do
    days
    |> Enum.with_index()
    |> Enum.reduce([], fn {date, index}, acc ->
      column_index = div(index, 7)

      if rem(index, 7) == 0 do
        {year, week_num} = :calendar.iso_week_number(Date.to_erl(date))
        [{year, week_num, column_index} | acc]
      else
        acc
      end
    end)
    |> Enum.reverse()
  end

  defp get_month_label_for_column(months, col_index) do
    case Enum.find(months, fn {_month, index} -> index == col_index end) do
      {month, _} -> String.split(month, " ") |> hd()
      nil -> ""
    end
  end
end
