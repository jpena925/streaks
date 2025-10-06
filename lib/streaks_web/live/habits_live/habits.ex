defmodule StreaksWeb.HabitsLive.Habits do
  use StreaksWeb, :live_view

  alias Streaks.Habits

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:new_habit_name, "")
      |> assign(:show_new_habit_form, false)

    if connected?(socket) do
      habits = Habits.list_habits(socket.assigns.current_scope.user)
      {:ok, assign(socket, :habits, habits)}
    else
      {:ok, assign(socket, :habits, [])}
    end
  end

  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  def handle_event("show_new_habit_form", _params, socket) do
    {:noreply, assign(socket, :show_new_habit_form, true)}
  end

  def handle_event("hide_new_habit_form", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_new_habit_form, false)
     |> assign(:new_habit_name, "")}
  end

  def handle_event("create_habit", %{"habit" => %{"name" => name}}, socket) do
    case Habits.create_habit(socket.assigns.current_scope.user, %{name: name}) do
      {:ok, _habit} ->
        habits = Habits.list_habits(socket.assigns.current_scope.user)

        {:noreply,
         socket
         |> assign(:habits, habits)
         |> assign(:show_new_habit_form, false)
         |> assign(:new_habit_name, "")
         |> put_flash(:info, "Habit created successfully!")}

      {:error, changeset} ->
        errors = changeset.errors |> Enum.map(fn {field, {msg, _}} -> "#{field}: #{msg}" end)

        {:noreply,
         socket
         |> put_flash(:error, "Error creating habit: #{Enum.join(errors, ", ")}")}
    end
  end

  def handle_event("rename_habit", %{"id" => id, "value" => new_name}, socket) do
    habit = Habits.get_habit!(String.to_integer(id), socket.assigns.current_scope.user)

    case Habits.update_habit(habit, %{name: new_name}) do
      {:ok, _habit} ->
        habits = Habits.list_habits(socket.assigns.current_scope.user)
        {:noreply, assign(socket, :habits, habits)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Error updating habit name")}
    end
  end

  def handle_event("delete_habit", %{"id" => id}, socket) do
    habit = Habits.get_habit!(String.to_integer(id), socket.assigns.current_scope.user)

    case Habits.delete_habit(habit) do
      {:ok, _habit} ->
        habits = Habits.list_habits(socket.assigns.current_scope.user)

        {:noreply,
         socket
         |> assign(:habits, habits)
         |> put_flash(:info, "Habit deleted successfully!")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Error deleting habit")}
    end
  end

  def handle_event("log_day", %{"habit_id" => habit_id, "date" => date}, socket) do
    habit = Habits.get_habit!(String.to_integer(habit_id), socket.assigns.current_scope.user)

    case Habits.log_habit_completion(habit, date) do
      {:ok, _completion} ->
        habits = Habits.list_habits(socket.assigns.current_scope.user)
        {:noreply, assign(socket, :habits, habits)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Error logging completion")}
    end
  end

  def handle_event("unlog_day", %{"habit_id" => habit_id, "date" => date}, socket) do
    habit = Habits.get_habit!(String.to_integer(habit_id), socket.assigns.current_scope.user)

    :ok = Habits.unlog_habit_completion(habit, date)
    habits = Habits.list_habits(socket.assigns.current_scope.user)

    {:noreply, assign(socket, :habits, habits)}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100 dark:from-gray-900 dark:to-gray-800 py-6 sm:py-12">
      <div class="mx-auto max-w-7xl px-3 sm:px-4 lg:px-8">
        <!-- Header -->
        <div class="mb-6 sm:mb-10 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
          <div>
            <h1 class="text-3xl sm:text-4xl font-bold text-gray-900 dark:text-white tracking-tight">
              Your Streaks
            </h1>
            <p class="mt-1 sm:mt-2 text-sm text-gray-600 dark:text-gray-400">
              Build consistency, one day at a time
            </p>
          </div>

          <button
            :if={!@show_new_habit_form}
            phx-click="show_new_habit_form"
            class="w-full sm:w-auto group relative inline-flex items-center justify-center gap-2 bg-blue-600 hover:bg-blue-700 dark:bg-blue-500 dark:hover:bg-blue-600 text-white font-semibold px-6 py-3 rounded-xl shadow-lg hover:shadow-xl transition-all duration-200 transform hover:scale-105"
          >
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4">
              </path>
            </svg>
            Add Habit
          </button>
        </div>

    <!-- New Habit Form -->
        <div
          :if={@show_new_habit_form}
          class="mb-6 sm:mb-8 p-4 sm:p-6 bg-white dark:bg-gray-800 rounded-2xl shadow-xl border border-gray-100 dark:border-gray-700"
        >
          <h3 class="text-base sm:text-lg font-semibold text-gray-900 dark:text-white mb-4">
            Create New Habit
          </h3>
          <form phx-submit="create_habit" class="flex flex-col sm:flex-row gap-3">
            <input
              type="text"
              name="habit[name]"
              value={@new_habit_name}
              placeholder="e.g., Morning workout, Read for 30 minutes..."
              class="flex-1 px-4 py-3 border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-900 dark:text-white placeholder-gray-500 dark:placeholder-gray-400 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 dark:focus:ring-blue-400 focus:border-transparent transition-all text-base"
              required
              autofocus
            />
            <div class="flex gap-3">
              <button
                type="submit"
                class="flex-1 sm:flex-none bg-blue-600 hover:bg-blue-700 dark:bg-blue-500 dark:hover:bg-blue-600 text-white font-semibold px-6 py-3 rounded-xl transition-all duration-200 hover:shadow-lg"
              >
                Create
              </button>
              <button
                type="button"
                phx-click="hide_new_habit_form"
                class="flex-1 sm:flex-none bg-gray-100 hover:bg-gray-200 dark:bg-gray-700 dark:hover:bg-gray-600 text-gray-700 dark:text-gray-300 font-semibold px-6 py-3 rounded-xl transition-all duration-200"
              >
                Cancel
              </button>
            </div>
          </form>
        </div>

    <!-- Empty State -->
        <div :if={@habits == []} class="text-center py-20">
          <svg
            class="mx-auto h-16 w-16 text-gray-400 dark:text-gray-500 mb-4"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"
            >
            </path>
          </svg>
          <h3 class="text-xl font-semibold text-gray-900 dark:text-white mb-2">No habits yet</h3>
          <p class="text-gray-600 dark:text-gray-400 mb-6">
            Create your first habit to start building your streaks!
          </p>
          <button
            phx-click="show_new_habit_form"
            class="inline-flex items-center gap-2 bg-blue-600 hover:bg-blue-700 dark:bg-blue-500 dark:hover:bg-blue-600 text-white font-semibold px-6 py-3 rounded-xl shadow-lg transition-all duration-200"
          >
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4">
              </path>
            </svg>
            Create Your First Habit
          </button>
        </div>

    <!-- Habits List -->
        <div class="space-y-6">
          <.habit_component
            :for={habit <- @habits}
            habit={habit}
            current_user={@current_scope.user}
          />
        </div>
      </div>
    </div>
    """
  end

  defp get_completion_dates(habit) do
    habit.completions
    |> Enum.map(& &1.completed_on)
    |> MapSet.new()
  end

  attr :habit, :map, required: true
  attr :current_user, :map, required: true

  def habit_component(assigns) do
    completion_dates = get_completion_dates(assigns.habit)
    habit_days = Habits.get_habit_days(assigns.habit)
    months = Habits.group_days_by_month(habit_days)
    streaks = Habits.calculate_streaks(assigns.habit)
    today = Date.utc_today()

    assigns =
      assigns
      |> assign(:completion_dates, completion_dates)
      |> assign(:habit_days, habit_days)
      |> assign(:months, months)
      |> assign(:streaks, streaks)
      |> assign(:today, today)

    ~H"""
    <div class="group bg-white dark:bg-gray-800 rounded-2xl shadow-lg hover:shadow-2xl transition-all duration-300 p-4 sm:p-8 border border-gray-100 dark:border-gray-700">
      <!-- Header -->
      <div class="flex flex-col sm:flex-row sm:items-center justify-between mb-4 sm:mb-6 gap-3">
        <div class="flex flex-col sm:flex-row sm:items-center gap-3 sm:gap-4 flex-1 min-w-0">
          <!-- Editable habit name -->
          <input
            type="text"
            value={@habit.name}
            phx-blur="rename_habit"
            phx-value-id={@habit.id}
            class="text-xl sm:text-2xl font-bold text-gray-900 dark:text-white bg-transparent border-none outline-none focus:bg-gray-50 dark:focus:bg-gray-700 focus:px-3 focus:py-2 rounded-lg transition-all min-w-0"
            style="width: 100%;"
          />

    <!-- Stats -->
          <div class="flex items-center gap-2 sm:gap-3 flex-wrap">
            <!-- Current streak badge -->
            <div class={[
              "flex items-center gap-1.5 sm:gap-2 px-3 sm:px-4 py-1.5 sm:py-2 rounded-xl font-bold text-xs sm:text-sm shadow-sm whitespace-nowrap",
              if(@streaks.current_streak > 0,
                do: "bg-gradient-to-r from-green-400 to-emerald-500 text-white",
                else: "bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300"
              )
            ]}>
              <svg class="w-3.5 h-3.5 sm:w-4 sm:h-4" fill="currentColor" viewBox="0 0 20 20">
                <path d="M12.395 2.553a1 1 0 00-1.45-.385c-.345.23-.614.558-.822.88-.214.33-.403.713-.57 1.116-.334.804-.614 1.768-.84 2.734a31.365 31.365 0 00-.613 3.58 2.64 2.64 0 01-.945-1.067c-.328-.68-.398-1.534-.398-2.654A1 1 0 005.05 6.05 6.981 6.981 0 003 11a7 7 0 1011.95-4.95c-.592-.591-.98-.985-1.348-1.467-.363-.476-.724-1.063-1.207-2.03zM12.12 15.12A3 3 0 017 13s.879.5 2.5.5c0-1 .5-4 1.25-4.5.5 1 .786 1.293 1.371 1.879A2.99 2.99 0 0113 13a2.99 2.99 0 01-.879 2.121z">
                </path>
              </svg>
              <span>
                {@streaks.current_streak} day{if @streaks.current_streak != 1, do: "s", else: ""}
              </span>
            </div>

    <!-- Longest streak -->
            <div class="flex items-center gap-1.5 sm:gap-2 px-3 sm:px-4 py-1.5 sm:py-2 bg-blue-50 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300 rounded-xl font-semibold text-xs sm:text-sm whitespace-nowrap">
              <svg
                class="w-3.5 h-3.5 sm:w-4 sm:h-4"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M5 3v4M3 5h4M6 17v4m-2-2h4m5-16l2.286 6.857L21 12l-5.714 2.143L13 21l-2.286-6.857L5 12l5.714-2.143L13 3z"
                >
                </path>
              </svg>
              <span>Best: {@streaks.longest_streak}</span>
            </div>
          </div>
        </div>

    <!-- Delete button -->
        <button
          phx-click="delete_habit"
          phx-value-id={@habit.id}
          data-confirm="Are you sure? This will permanently delete this habit and all its completion data."
          class="sm:opacity-0 group-hover:opacity-100 text-gray-400 dark:text-gray-500 hover:text-red-500 dark:hover:text-red-400 hover:bg-red-50 dark:hover:bg-red-900/20 p-2 rounded-lg transition-all duration-200 self-end sm:self-center"
          title="Delete habit"
        >
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
            >
            </path>
          </svg>
        </button>
      </div>

    <!-- Grid container -->
      <div class="bg-gray-50 dark:bg-gray-900/50 rounded-xl p-3 sm:p-4">
        <!-- Scrollable container for both labels and grid -->
        <div class="overflow-x-auto pb-2">
          <div class="inline-block min-w-full">
            <!-- Month labels -->
            <div class="mb-2 sm:mb-3 text-xs font-medium text-gray-600 dark:text-gray-400">
              <div
                class="grid grid-flow-col gap-1"
                style="grid-template-columns: repeat(53, 14px);"
              >
                <%= for {month, column_index} <- @months do %>
                  <span style={"grid-column-start: #{column_index + 1};"} class="text-center">
                    {String.split(month, " ") |> hd()}
                  </span>
                <% end %>
              </div>
            </div>

    <!-- Habit completion grid -->
            <div class="grid grid-flow-col grid-rows-7 gap-1 sm:gap-1.5 p-2">
              <%= for {day, index} <- Enum.with_index(@habit_days) do %>
                <.habit_cube
                  date={day}
                  completed={MapSet.member?(@completion_dates, day)}
                  habit_id={@habit.id}
                  is_today={day == @today}
                  is_future={Date.compare(day, @today) == :gt}
                />
              <% end %>
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
    </div>
    """
  end

  # Individual habit cube component
  attr :date, Date, required: true
  attr :completed, :boolean, required: true
  attr :habit_id, :integer, required: true
  attr :is_today, :boolean, default: false
  attr :is_future, :boolean, default: false

  def habit_cube(assigns) do
    ~H"""
    <div
      class={[
        "w-3.5 h-3.5 rounded-md border-2 transition-all duration-200",
        if(@is_future,
          do: "bg-gray-100 dark:bg-gray-700 cursor-not-allowed opacity-30 border-transparent",
          else: "cursor-pointer transform hover:scale-125"
        ),
        if(!@is_future && @completed,
          do:
            "bg-gradient-to-br from-green-400 to-green-600 hover:from-green-500 hover:to-green-700 border-transparent shadow-sm",
          else: nil
        ),
        if(!@is_future && !@completed,
          do:
            "bg-gray-200 dark:bg-gray-700 hover:bg-gray-300 dark:hover:bg-gray-600 border-transparent hover:border-gray-400 dark:hover:border-gray-500",
          else: nil
        ),
        if(@is_today,
          do: "ring-2 ring-blue-500 dark:ring-blue-400 ring-offset-1 dark:ring-offset-gray-900",
          else: nil
        )
      ]}
      title={Date.to_iso8601(@date)}
      phx-click={if(!@is_future, do: if(@completed, do: "unlog_day", else: "log_day"), else: nil)}
      phx-value-habit_id={@habit_id}
      phx-value-date={Date.to_iso8601(@date)}
    >
    </div>
    """
  end
end
