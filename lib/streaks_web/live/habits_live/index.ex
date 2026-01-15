defmodule StreaksWeb.HabitsLive.Index do
  use StreaksWeb, :live_view

  alias Streaks.Habits
  alias Streaks.Habits.Habit
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
      |> assign(:is_edit_mode, false)
      |> assign(:loading, true)
      |> assign(:show_archived, false)
      |> assign_new_habit_form()

    socket =
      if connected?(socket) do
        time_zone = get_connect_params(socket)["timeZone"] || "UTC"
        habits = Habits.list_habits(socket.assigns.current_scope.user)
        archived_habits = Habits.list_archived_habits(socket.assigns.current_scope.user)

        socket
        |> assign(:timezone, time_zone)
        |> assign(:habits, habits)
        |> assign(:archived_habits, archived_habits)
        |> assign(:loading, false)
      else
        socket
        |> assign(:timezone, "UTC")
        |> assign(:habits, [])
        |> assign(:archived_habits, [])
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
    changeset =
      %Habit{user_id: socket.assigns.current_scope.user.id}
      |> Habit.changeset(habit_params)
      |> Map.put(:action, :validate)

    form = to_form(changeset)
    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("create_habit", %{"habit" => habit_params}, socket) do
    attrs =
      %{
        name: habit_params["name"],
        has_quantity: habit_params["has_quantity"]
      }
      |> maybe_add_quantity_config(habit_params)

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

  def handle_event("archive_habit", %{"id" => id}, socket) do
    with {:ok, habit} <- fetch_user_habit(id, socket),
         {:ok, _habit} <- Habits.archive_habit(habit) do
      habits = Habits.list_habits(socket.assigns.current_scope.user)
      archived_habits = Habits.list_archived_habits(socket.assigns.current_scope.user)

      {:noreply,
       socket
       |> assign(:habits, habits)
       |> assign(:archived_habits, archived_habits)
       |> put_flash(:info, "Habit archived successfully!")}
    else
      :error ->
        {:noreply, habit_not_found(socket)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Error archiving habit")}
    end
  end

  def handle_event("unarchive_habit", %{"id" => id}, socket) do
    habit =
      Enum.find(socket.assigns.archived_habits, fn h -> h.id == String.to_integer(id) end)

    case habit do
      nil ->
        {:noreply, put_flash(socket, :error, "Archived habit not found")}

      habit ->
        case Habits.unarchive_habit(habit) do
          {:ok, _habit} ->
            habits = Habits.list_habits(socket.assigns.current_scope.user)
            archived_habits = Habits.list_archived_habits(socket.assigns.current_scope.user)

            {:noreply,
             socket
             |> assign(:habits, habits)
             |> assign(:archived_habits, archived_habits)
             |> put_flash(:info, "Habit restored successfully!")}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Error restoring habit")}
        end
    end
  end

  def handle_event("delete_habit", %{"id" => id}, socket) do
    habit =
      Enum.find(socket.assigns.archived_habits, fn h -> h.id == String.to_integer(id) end)

    case habit do
      nil ->
        {:noreply, put_flash(socket, :error, "Archived habit not found")}

      habit ->
        case Habits.delete_habit(habit) do
          {:ok, _habit} ->
            archived_habits = Habits.list_archived_habits(socket.assigns.current_scope.user)

            {:noreply,
             socket
             |> assign(:archived_habits, archived_habits)
             |> put_flash(:info, "Habit permanently deleted!")}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Error deleting habit")}
        end
    end
  end

  def handle_event("toggle_archived", _params, socket) do
    {:noreply, assign(socket, :show_archived, !socket.assigns.show_archived)}
  end

  def handle_event("log_day", %{"habit_id" => habit_id, "date" => date}, socket) do
    with {:ok, habit} <- fetch_user_habit(habit_id, socket) do
      if habit.has_quantity do
        {:noreply,
         socket
         |> assign(:show_quantity_modal, true)
         |> assign(:quantity_habit_id, habit_id)
         |> assign(:quantity_date, date)
         |> assign(:quantity_value, "")
         |> assign(:is_edit_mode, false)}
      else
        case Habits.log_habit_completion(habit, date) do
          {:ok, completion} ->
            {:noreply, add_completion_to_habit(socket, habit.id, completion)}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Error logging completion")}
        end
      end
    else
      :error -> {:noreply, habit_not_found(socket)}
    end
  end

  def handle_event("edit_quantity", %{"habit_id" => habit_id, "date" => date}, socket) do
    with {:ok, habit} <- fetch_user_habit(habit_id, socket),
         completion <- Habits.get_completion(habit, date),
         true <- completion != nil do
      {:noreply,
       socket
       |> assign(:show_quantity_modal, true)
       |> assign(:quantity_habit_id, habit_id)
       |> assign(:quantity_date, date)
       |> assign(:quantity_value, to_string(completion.quantity))
       |> assign(:is_edit_mode, true)}
    else
      :error ->
        {:noreply, habit_not_found(socket)}

      _ ->
        {:noreply, put_flash(socket, :error, "Completion not found")}
    end
  end

  def handle_event("unlog_day", %{"habit_id" => habit_id, "date" => date}, socket) do
    with {:ok, habit} <- fetch_user_habit(habit_id, socket) do
      :ok = Habits.unlog_habit_completion(habit, date)
      {:noreply, remove_completion_from_habit(socket, habit.id, date)}
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
     |> assign(:quantity_value, "")
     |> assign(:is_edit_mode, false)}
  end

  def handle_event("submit_quantity", %{"quantity" => quantity_str}, socket) do
    with {quantity, _} <- Integer.parse(quantity_str),
         true <- quantity > 0,
         {:ok, habit} <- fetch_user_habit(socket.assigns.quantity_habit_id, socket),
         {:ok, completion} <-
           Habits.log_habit_completion(habit, socket.assigns.quantity_date, quantity) do
      {:noreply,
       socket
       |> add_completion_to_habit(habit.id, completion)
       |> assign(:show_quantity_modal, false)
       |> assign(:quantity_habit_id, nil)
       |> assign(:quantity_date, nil)
       |> assign(:quantity_value, "")
       |> assign(:is_edit_mode, false)}
    else
      :error ->
        {:noreply, habit_not_found(socket)}

      _ ->
        {:noreply, put_flash(socket, :error, "Please enter a valid positive number")}
    end
  end

  def handle_event("delete_quantity", _params, socket) do
    with {:ok, habit} <- fetch_user_habit(socket.assigns.quantity_habit_id, socket) do
      :ok = Habits.unlog_habit_completion(habit, socket.assigns.quantity_date)

      {:noreply,
       socket
       |> remove_completion_from_habit(habit.id, socket.assigns.quantity_date)
       |> assign(:show_quantity_modal, false)
       |> assign(:quantity_habit_id, nil)
       |> assign(:quantity_date, nil)
       |> assign(:quantity_value, "")
       |> assign(:is_edit_mode, false)
       |> put_flash(:info, "Completion deleted successfully")}
    else
      :error ->
        {:noreply, habit_not_found(socket)}
    end
  end

  def handle_event("move_habit_up", %{"id" => id}, socket) do
    move_habit(id, :up, socket)
  end

  def handle_event("move_habit_down", %{"id" => id}, socket) do
    move_habit(id, :down, socket)
  end

  @spec reset_new_habit_form(Phoenix.LiveView.Socket.t()) :: Phoenix.LiveView.Socket.t()
  defp reset_new_habit_form(socket) do
    socket
    |> assign(:show_new_habit_form, false)
    |> assign(:new_habit_name, "")
    |> assign_new_habit_form()
  end

  @spec assign_new_habit_form(Phoenix.LiveView.Socket.t()) :: Phoenix.LiveView.Socket.t()
  defp assign_new_habit_form(socket) do
    changeset = Habit.changeset(%Habit{}, %{})
    assign(socket, :form, to_form(changeset, as: :habit))
  end

  @spec fetch_user_habit(integer() | String.t(), Phoenix.LiveView.Socket.t()) ::
          {:ok, Streaks.Habits.Habit.t()} | :error
  defp fetch_user_habit(habit_id, socket) when is_binary(habit_id) do
    fetch_user_habit(String.to_integer(habit_id), socket)
  end

  defp fetch_user_habit(habit_id, socket) when is_integer(habit_id) do
    case Habits.get_habit(habit_id, socket.assigns.current_scope.user) do
      nil -> :error
      habit -> {:ok, habit}
    end
  end

  @spec habit_not_found(Phoenix.LiveView.Socket.t()) :: Phoenix.LiveView.Socket.t()
  defp habit_not_found(socket) do
    habits = Habits.list_habits(socket.assigns.current_scope.user)
    archived_habits = Habits.list_archived_habits(socket.assigns.current_scope.user)

    socket
    |> assign(:habits, habits)
    |> assign(:archived_habits, archived_habits)
    |> put_flash(:error, "Habit not found. It may have been archived or deleted.")
  end

  defp move_habit(id, direction, socket) do
    with {:ok, habit} <- fetch_user_habit(id, socket),
         habits <- socket.assigns.habits,
         {:ok, current_index} <- find_habit_index(habits, habit.id),
         {:ok, swap_index} <- get_swap_index(current_index, direction, length(habits)) do
      new_order = swap_habit_ids(habits, current_index, swap_index)
      reorder_and_refresh(socket, new_order)
    else
      :error -> {:noreply, habit_not_found(socket)}
      {:error, :boundary} -> {:noreply, socket}
    end
  end

  defp find_habit_index(habits, habit_id) do
    case Enum.find_index(habits, &(&1.id == habit_id)) do
      nil -> :error
      index -> {:ok, index}
    end
  end

  defp get_swap_index(current_index, :up, _length) when current_index > 0 do
    {:ok, current_index - 1}
  end

  defp get_swap_index(current_index, :down, length) when current_index < length - 1 do
    {:ok, current_index + 1}
  end

  defp get_swap_index(_current_index, _direction, _length), do: {:error, :boundary}

  defp swap_habit_ids(habits, index1, index2) do
    habits
    |> List.update_at(index1, fn _ -> Enum.at(habits, index2) end)
    |> List.update_at(index2, fn _ -> Enum.at(habits, index1) end)
    |> Enum.map(& &1.id)
  end

  defp reorder_and_refresh(socket, new_order) do
    case Habits.reorder_habits(socket.assigns.current_scope.user, new_order) do
      {:ok, _habits} ->
        habits = Habits.list_habits(socket.assigns.current_scope.user)
        {:noreply, assign(socket, :habits, habits)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to reorder habits")}
    end
  end

  defp format_relative_time(datetime) do
    now = DateTime.utc_now()
    diff_seconds = DateTime.diff(now, datetime)

    cond do
      diff_seconds < 60 -> "just now"
      diff_seconds < 3600 -> "#{div(diff_seconds, 60)} minutes ago"
      diff_seconds < 86_400 -> "#{div(diff_seconds, 3600)} hours ago"
      diff_seconds < 604_800 -> "#{div(diff_seconds, 86_400)} days ago"
      diff_seconds < 2_592_000 -> "#{div(diff_seconds, 604_800)} weeks ago"
      diff_seconds < 31_536_000 -> "#{div(diff_seconds, 2_592_000)} months ago"
      true -> "#{div(diff_seconds, 31_536_000)} years ago"
    end
  end

  defp add_completion_to_habit(socket, habit_id, completion) do
    update_habit_in_list(socket, habit_id, fn habit ->
      completions =
        habit.completions
        |> Enum.reject(&(&1.completed_on == completion.completed_on))
        |> List.insert_at(0, completion)

      %{habit | completions: completions}
    end)
  end

  defp remove_completion_from_habit(socket, habit_id, date) do
    parsed_date = parse_date(date)

    update_habit_in_list(socket, habit_id, fn habit ->
      completions = Enum.reject(habit.completions, &(&1.completed_on == parsed_date))
      %{habit | completions: completions}
    end)
  end

  defp update_habit_in_list(socket, habit_id, update_fn) do
    habits =
      Enum.map(socket.assigns.habits, fn habit ->
        if habit.id == habit_id do
          update_fn.(habit)
        else
          habit
        end
      end)

    assign(socket, :habits, habits)
  end

  defp parse_date(%Date{} = date), do: date

  defp parse_date(date) when is_binary(date) do
    case Date.from_iso8601(date) do
      {:ok, parsed} -> parsed
      {:error, _} -> nil
    end
  end

  defp maybe_add_quantity_config(attrs, params) do
    if params["has_quantity"] == "true" do
      attrs
      |> Map.put(:quantity_low, parse_int(params["quantity_low"], 1))
      |> Map.put(:quantity_high, parse_int(params["quantity_high"], 10))
      |> Map.put(:quantity_unit, params["quantity_unit"])
    else
      attrs
    end
  end

  defp parse_int(nil, default), do: default
  defp parse_int("", default), do: default

  defp parse_int(value, default) when is_binary(value) do
    case Integer.parse(value) do
      {int, _} -> int
      :error -> default
    end
  end
end
