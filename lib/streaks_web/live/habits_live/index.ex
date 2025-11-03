defmodule StreaksWeb.HabitsLive.Index do
  use StreaksWeb, :live_view

  alias Streaks.Habits
  alias StreaksWeb.HabitsLive.HabitCard
  alias StreaksWeb.HabitsLive.QuantityModal

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:new_habit_name, "")
      |> assign(:show_new_habit_form, false)
      |> assign(:show_quantity_modal, false)
      |> assign(:quantity_habit_id, nil)
      |> assign(:quantity_date, nil)
      |> assign(:quantity_value, "")
      |> assign(:form, to_form(%{"name" => "", "has_quantity" => false}, as: :habit))

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
    form = to_form(habit_params, as: :habit)
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

  def handle_event("reorder", %{"ids" => ids}, socket) do
    habit_ids = Enum.map(ids, &String.to_integer/1)

    case Habits.reorder_habits(socket.assigns.current_scope.user, habit_ids) do
      {:ok, _habits} ->
        habits = Habits.list_habits(socket.assigns.current_scope.user)
        {:noreply, assign(socket, :habits, habits)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to reorder habits")}
    end
  end

  defp reset_new_habit_form(socket) do
    socket
    |> assign(:show_new_habit_form, false)
    |> assign(:new_habit_name, "")
    |> assign(:form, to_form(%{"name" => "", "has_quantity" => false}, as: :habit))
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
