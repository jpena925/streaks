defmodule StreaksWeb.HabitsLive.Index do
  use StreaksWeb, :live_view

  alias Streaks.Habits

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:new_habit_name, "")
      |> assign(:show_new_habit_form, false)
      |> assign(:show_quantity_modal, false)
      |> assign(:quantity_habit_id, nil)
      |> assign(:quantity_date, nil)
      |> assign(:quantity_value, "")
      |> assign(:form, to_form(%{"name" => "", "has_quantity" => false}))

    socket =
      if connected?(socket) do
        time_zone = get_connect_params(socket)["timeZone"] || "UTC"
        habits = Habits.list_habits(socket.assigns.current_scope.user)

        socket
        |> assign(:timezone, time_zone)
        |> assign(:habits, habits)
      else
        socket
        |> assign(:timezone, "UTC")
        |> assign(:habits, [])
      end

    {:ok, socket}
  end

  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  def handle_event("show_new_habit_form", _params, socket) do
    {:noreply, assign(socket, :show_new_habit_form, true)}
  end

  def handle_event("hide_new_habit_form", _params, socket) do
    {:noreply, reset_new_habit_form(socket)}
  end

  def handle_event("validate", %{"habit" => habit_params}, socket) do
    form = to_form(habit_params)
    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("create_habit", %{"habit" => habit_params}, socket) do
    attrs = %{
      name: habit_params["name"],
      has_quantity: habit_params["has_quantity"]
    }

    case Habits.create_habit(socket.assigns.current_scope.user, attrs) do
      {:ok, _habit} ->
        habits = Habits.list_habits(socket.assigns.current_scope.user)

        {:noreply,
         socket
         |> assign(:habits, habits)
         |> reset_new_habit_form()
         |> put_flash(:info, "Habit created successfully!")}

      {:error, changeset} ->
        errors = changeset.errors |> Enum.map(fn {field, {msg, _}} -> "#{field}: #{msg}" end)

        {:noreply,
         socket
         |> put_flash(:error, "Error creating habit: #{Enum.join(errors, ", ")}")}
    end
  end

  def handle_event("rename_habit", %{"id" => id, "value" => new_name}, socket) do
    with {:ok, habit} <- fetch_user_habit(id, socket),
         {:ok, _habit} <- Habits.update_habit(habit, %{name: new_name}) do
      habits = Habits.list_habits(socket.assigns.current_scope.user)
      {:noreply, assign(socket, :habits, habits)}
    else
      :error ->
        {:noreply, habit_not_found(socket)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to rename habit")}
    end
  end

  def handle_event("delete_habit", %{"id" => id}, socket) do
    with {:ok, habit} <- fetch_user_habit(id, socket),
         {:ok, _habit} <- Habits.delete_habit(habit) do
      habits = Habits.list_habits(socket.assigns.current_scope.user)

      {:noreply,
       socket
       |> assign(:habits, habits)
       |> put_flash(:info, "Habit deleted successfully!")}
    else
      :error ->
        {:noreply, habit_not_found(socket)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Error deleting habit")}
    end
  end

  def handle_event("log_day", %{"habit_id" => habit_id, "date" => date}, socket) do
    with {:ok, habit} <- fetch_user_habit(habit_id, socket) do
      if habit.has_quantity do
        {:noreply,
         socket
         |> assign(:show_quantity_modal, true)
         |> assign(:quantity_habit_id, habit_id)
         |> assign(:quantity_date, date)
         |> assign(:quantity_value, "")}
      else
        case Habits.log_habit_completion(habit, date) do
          {:ok, _completion} ->
            habits = Habits.list_habits(socket.assigns.current_scope.user)
            {:noreply, assign(socket, :habits, habits)}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Error logging completion")}
        end
      end
    else
      :error -> {:noreply, habit_not_found(socket)}
    end
  end

  def handle_event("unlog_day", %{"habit_id" => habit_id, "date" => date}, socket) do
    with {:ok, habit} <- fetch_user_habit(habit_id, socket) do
      :ok = Habits.unlog_habit_completion(habit, date)
      habits = Habits.list_habits(socket.assigns.current_scope.user)
      {:noreply, assign(socket, :habits, habits)}
    else
      :error -> {:noreply, habit_not_found(socket)}
    end
  end

  def handle_event("close_quantity_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_quantity_modal, false)
     |> assign(:quantity_habit_id, nil)
     |> assign(:quantity_date, nil)
     |> assign(:quantity_value, "")}
  end

  def handle_event("submit_quantity", %{"quantity" => quantity_str}, socket) do
    with {quantity, _} <- Integer.parse(quantity_str),
         true <- quantity > 0,
         {:ok, habit} <- fetch_user_habit(socket.assigns.quantity_habit_id, socket),
         {:ok, _completion} <-
           Habits.log_habit_completion(habit, socket.assigns.quantity_date, quantity) do
      habits = Habits.list_habits(socket.assigns.current_scope.user)

      {:noreply,
       socket
       |> assign(:habits, habits)
       |> assign(:show_quantity_modal, false)
       |> assign(:quantity_habit_id, nil)
       |> assign(:quantity_date, nil)
       |> assign(:quantity_value, "")}
    else
      :error ->
        {:noreply, habit_not_found(socket)}

      _ ->
        {:noreply, put_flash(socket, :error, "Please enter a valid positive number")}
    end
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

  attr :habit, :map, required: true
  attr :current_user, :map, required: true
  attr :timezone, :string, required: true

  def habit_component(assigns) do
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
      <div class="mb-4 sm:mb-6">
        <!-- Editable habit name -->
        <input
          type="text"
          value={@habit.name}
          phx-blur="rename_habit"
          phx-value-id={@habit.id}
          class="text-xl sm:text-2xl font-bold text-gray-900 dark:text-white bg-transparent border-none outline-none focus:bg-gray-50 dark:focus:bg-gray-700 focus:px-3 focus:py-2 rounded-lg transition-all w-full mb-3"
        />
        
    <!-- Stats and Delete Button Row -->
        <div class="flex items-center justify-between gap-2">
          <div class="flex items-center gap-2 sm:gap-3 flex-wrap">
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
              <.habit_cube
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

  # Individual habit cube component
  attr :date, Date, required: true
  attr :completed, :boolean, required: true
  attr :quantity, :integer, default: nil
  attr :habit_id, :integer, required: true
  attr :is_today, :boolean, default: false
  attr :is_future, :boolean, default: false

  def habit_cube(assigns) do
    # Build title with quantity if present
    title =
      if assigns.quantity do
        "#{Date.to_iso8601(assigns.date)} - Quantity: #{assigns.quantity}"
      else
        Date.to_iso8601(assigns.date)
      end

    assigns = assign(assigns, :title, title)

    ~H"""
    <div
      class={[
        "w-3.5 h-3.5 rounded-md border-2 transition-all duration-200 relative group",
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
      title={@title}
      phx-click={if(!@is_future, do: if(@completed, do: "unlog_day", else: "log_day"), else: nil)}
      phx-value-habit_id={@habit_id}
      phx-value-date={Date.to_iso8601(@date)}
    >
      <%!-- Show quantity badge on hover if present --%>
      <div
        :if={@quantity && @completed}
        class="hidden group-hover:block absolute -top-8 left-1/2 transform -translate-x-1/2 bg-gray-900 dark:bg-gray-100 text-white dark:text-gray-900 text-xs font-bold px-2 py-1 rounded shadow-lg whitespace-nowrap z-10"
      >
        {@quantity}
      </div>
    </div>
    """
  end

  defp reset_new_habit_form(socket) do
    socket
    |> assign(:show_new_habit_form, false)
    |> assign(:new_habit_name, "")
    |> assign(:form, to_form(%{"name" => "", "has_quantity" => false}))
  end

  defp fetch_user_habit(habit_id, socket) when is_binary(habit_id) do
    fetch_user_habit(String.to_integer(habit_id), socket)
  end

  defp fetch_user_habit(habit_id, socket) when is_integer(habit_id) do
    case Habits.get_habit(habit_id, socket.assigns.current_scope.user) do
      nil -> :error
      habit -> {:ok, habit}
    end
  end

  defp habit_not_found(socket) do
    habits = Habits.list_habits(socket.assigns.current_scope.user)

    socket
    |> assign(:habits, habits)
    |> put_flash(:error, "Habit not found. It may have been deleted.")
  end
end
