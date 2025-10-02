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
    <div class="min-h-screen bg-gray-50 py-8">
      <div class="mx-auto max-w-6xl px-4">
        <div class="mb-8 flex items-center justify-between">
          <h1 class="text-3xl font-bold text-gray-900">Your Streaks</h1>

          <button
            :if={!@show_new_habit_form}
            phx-click="show_new_habit_form"
            class="bg-blue-600 hover:bg-blue-700 text-white font-medium py-2 px-4 rounded-lg transition-colors duration-200"
          >
            Add New Habit
          </button>
        </div>
        
    <!-- New Habit Form -->
        <div :if={@show_new_habit_form} class="mb-6 p-4 bg-white rounded-lg shadow">
          <form phx-submit="create_habit" class="flex gap-2">
            <input
              type="text"
              name="habit[name]"
              value={@new_habit_name}
              placeholder="Enter habit name..."
              class="flex-1 px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              required
            />
            <button
              type="submit"
              class="bg-blue-600 hover:bg-blue-700 text-white font-medium py-2 px-4 rounded-lg transition-colors duration-200"
            >
              Create
            </button>
            <button
              type="button"
              phx-click="hide_new_habit_form"
              class="bg-gray-500 hover:bg-gray-600 text-white font-medium py-2 px-4 rounded-lg transition-colors duration-200"
            >
              Cancel
            </button>
          </form>
        </div>
        
    <!-- Habits List -->
        <div :if={@habits == []} class="text-center py-12">
          <p class="text-gray-500 text-lg">No habits yet. Create your first habit to get started!</p>
        </div>

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

  # Helper function to calculate completion dates for a habit
  defp get_completion_dates(habit) do
    habit.completions
    |> Enum.map(& &1.completed_on)
    |> MapSet.new()
  end

  # Habit component
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
    <div class="bg-white rounded-lg shadow-md p-6">
      <div class="flex items-center justify-between mb-4">
        <div class="flex items-center gap-4 flex-1">
          <!-- Editable habit name -->
          <input
            type="text"
            value={@habit.name}
            phx-blur="rename_habit"
            phx-value-id={@habit.id}
            class="text-xl font-bold bg-transparent border-none outline-none focus:bg-gray-50 focus:px-2 focus:py-1 rounded"
            style="width: auto; min-width: 100px;"
          />
          
    <!-- Current streak badge -->
          <span class={[
            "px-3 py-1 rounded-full text-xs font-bold",
            if(@streaks.current_streak > 0,
              do: "bg-green-100 text-green-800",
              else: "bg-gray-100 text-gray-600"
            )
          ]}>
            {@streaks.current_streak} DAY STREAK
          </span>
          
    <!-- Longest streak -->
          <span class="text-sm text-gray-500">
            Best: {@streaks.longest_streak} days
          </span>
        </div>
        
    <!-- Delete button -->
        <button
          phx-click="delete_habit"
          phx-value-id={@habit.id}
          data-confirm="Are you sure? This will delete all completion data."
          class="text-red-500 hover:text-red-700 p-2"
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
      
    <!-- Month labels -->
      <div class="mb-2 text-xs text-gray-500 overflow-x-auto w-fit">
        <div
          class="grid grid-flow-col gap-1"
          style="grid-template-columns: repeat(53, 12px);"
        >
          <%= for {month, column_index} <- @months do %>
            <span style={"grid-column-start: #{column_index + 1};"}>
              {String.split(month, " ") |> hd()}
            </span>
          <% end %>
        </div>
      </div>
      
    <!-- Habit completion grid -->
      <div class="grid grid-flow-col grid-rows-7 gap-1 overflow-x-auto w-fit">
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
        "w-3 h-3 rounded-sm border transition-colors",
        if(@is_future,
          do: "bg-gray-100 cursor-not-allowed opacity-40",
          else: "cursor-pointer"
        ),
        if(!@is_future && @completed, do: "bg-green-500 hover:bg-green-600", else: nil),
        if(!@is_future && !@completed, do: "bg-gray-200 hover:bg-gray-300", else: nil),
        if(@is_today, do: "border-gray-800", else: "border-transparent")
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
