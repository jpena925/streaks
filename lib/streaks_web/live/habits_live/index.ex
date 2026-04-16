defmodule StreaksWeb.HabitsLive.Index do
  use StreaksWeb, :live_view

  alias Streaks.Habits
  alias Streaks.Habits.Habit
  alias Streaks.StreakCache
  alias StreaksWeb.HabitsLive.HabitCard
  alias StreaksWeb.HabitsLive.HabitSettingsModal
  alias StreaksWeb.HabitsLive.QualitativeModal
  alias StreaksWeb.HabitsLive.QuantityModal
  alias StreaksWeb.HabitsLive.WeeklyNoteModal

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
      |> assign(:show_settings_modal, false)
      |> assign(:settings_habit, nil)
      |> assign(:settings_tracking_mode, :binary)
      |> assign(:settings_qual_rows, [])
      |> assign(:show_qualitative_modal, false)
      |> assign(:qualitative_habit_id, nil)
      |> assign(:qualitative_date, nil)
      |> assign(:qualitative_is_edit, false)
      |> assign(:qualitative_modal_options, [])
      |> assign(:show_weekly_note_modal, false)
      |> assign(:weekly_note_habit_id, nil)
      |> assign(:weekly_note_year, nil)
      |> assign(:weekly_note_week, nil)
      |> assign(:weekly_note_text, "")
      |> assign(:weekly_note_has_existing, false)
      |> assign(:weekly_notes_by_habit, %{})
      |> assign_new_habit_form()

    socket =
      if connected?(socket) do
        time_zone = get_connect_params(socket)["timeZone"] || "UTC"
        habits = Habits.list_habits(socket.assigns.current_scope.user)
        archived_habits = Habits.list_archived_habits(socket.assigns.current_scope.user)
        weekly_notes_by_habit = load_weekly_notes_for_habits(habits, time_zone)

        socket
        |> assign(:timezone, time_zone)
        |> assign(:habits, habits)
        |> assign(:archived_habits, archived_habits)
        |> assign(:weekly_notes_by_habit, weekly_notes_by_habit)
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
    {:noreply,
     socket
     |> assign(:show_new_habit_form, true)
     |> assign(:create_qual_rows, initial_create_qual_rows(2))}
  end

  def handle_event("hide_new_habit_form", _params, socket) do
    {:noreply, reset_new_habit_form(socket)}
  end

  def handle_event("validate", %{"habit" => habit_params}, socket) do
    raw_qual = Map.get(habit_params, "qualitative_options")
    mode = parse_tracking_mode(habit_params["tracking_mode"] || "binary")

    create_qual_rows =
      if mode == :qualitative do
        build_create_qual_rows_from_params(raw_qual, socket.assigns.create_qual_rows)
      else
        socket.assigns.create_qual_rows
      end

    habit_params = normalize_create_habit_params(habit_params, finalize_qualitative_ids: false)

    changeset =
      %Habit{user_id: socket.assigns.current_scope.user.id}
      |> Habit.changeset(habit_params)
      |> Map.put(:action, :validate)

    form = to_form(changeset)

    {:noreply,
     socket
     |> assign(:form, form)
     |> assign(:create_qual_rows, create_qual_rows)}
  end

  def handle_event("create_qual_add_row", _params, socket) do
    rows = socket.assigns.create_qual_rows

    if length(rows) >= 5 do
      {:noreply, socket}
    else
      i = length(rows)

      new_row = %{
        index: i,
        id: "new-#{i}",
        color: default_qual_color_at(i),
        label: ""
      }

      {:noreply, assign(socket, :create_qual_rows, rows ++ [new_row])}
    end
  end

  def handle_event("create_qual_remove_row", _params, socket) do
    rows = socket.assigns.create_qual_rows

    if length(rows) <= 2 do
      {:noreply, socket}
    else
      new_rows =
        rows
        |> Enum.take(length(rows) - 1)
        |> reindex_new_habit_qual_rows()

      {:noreply, assign(socket, :create_qual_rows, new_rows)}
    end
  end

  def handle_event("create_habit", %{"habit" => habit_params}, socket) do
    habit_params = normalize_create_habit_params(habit_params, finalize_qualitative_ids: true)
    mode = parse_tracking_mode(habit_params["tracking_mode"] || "binary")

    attrs = %{
      name: habit_params["name"],
      tracking_mode: mode,
      qualitative_options: habit_params["qualitative_options"] || []
    }

    attrs =
      if mode == :quantity do
        attrs
        |> Map.put(:quantity_low, parse_int(habit_params["quantity_low"], 1))
        |> Map.put(:quantity_high, parse_int(habit_params["quantity_high"], 10))
      else
        attrs
      end

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
      cond do
        habit.tracking_mode == :quantity ->
          {:noreply,
           socket
           |> assign(:show_quantity_modal, true)
           |> assign(:quantity_habit_id, habit_id)
           |> assign(:quantity_date, date)
           |> assign(:quantity_value, "")
           |> assign(:is_edit_mode, false)}

        habit.tracking_mode == :qualitative ->
          {:noreply,
           socket
           |> assign(:show_qualitative_modal, true)
           |> assign(:qualitative_habit_id, habit_id)
           |> assign(:qualitative_date, date)
           |> assign(:qualitative_is_edit, false)
           |> assign(:qualitative_modal_options, habit.qualitative_options || [])}

        true ->
          case Habits.log_habit_completion(habit, date) do
            {:ok, completion} ->
              StreakCache.invalidate(socket.assigns.current_scope.user.id, habit.id)
              {:noreply, add_completion_to_habit(socket, habit.id, completion)}

            {:error, _reason} ->
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
      StreakCache.invalidate(socket.assigns.current_scope.user.id, habit.id)
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
      StreakCache.invalidate(socket.assigns.current_scope.user.id, habit.id)

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
      StreakCache.invalidate(socket.assigns.current_scope.user.id, habit.id)

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

  def handle_event("close_qualitative_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_qualitative_modal, false)
     |> assign(:qualitative_habit_id, nil)
     |> assign(:qualitative_date, nil)
     |> assign(:qualitative_is_edit, false)
     |> assign(:qualitative_modal_options, [])}
  end

  def handle_event("submit_qualitative", %{"option_id" => option_id}, socket) do
    with {:ok, habit} <- fetch_user_habit(socket.assigns.qualitative_habit_id, socket),
         {:ok, completion} <-
           Habits.log_habit_completion(habit, socket.assigns.qualitative_date, option_id) do
      StreakCache.invalidate(socket.assigns.current_scope.user.id, habit.id)

      {:noreply,
       socket
       |> add_completion_to_habit(habit.id, completion)
       |> assign(:show_qualitative_modal, false)
       |> assign(:qualitative_habit_id, nil)
       |> assign(:qualitative_date, nil)
       |> assign(:qualitative_is_edit, false)
       |> assign(:qualitative_modal_options, [])}
    else
      :error ->
        {:noreply, habit_not_found(socket)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not log that option")}
    end
  end

  def handle_event("edit_qualitative", %{"habit_id" => habit_id, "date" => date}, socket) do
    with {:ok, habit} <- fetch_user_habit(habit_id, socket),
         completion <- Habits.get_completion(habit, date),
         true <- completion != nil do
      {:noreply,
       socket
       |> assign(:show_qualitative_modal, true)
       |> assign(:qualitative_habit_id, habit_id)
       |> assign(:qualitative_date, date)
       |> assign(:qualitative_is_edit, true)
       |> assign(:qualitative_modal_options, habit.qualitative_options || [])}
    else
      :error ->
        {:noreply, habit_not_found(socket)}

      _ ->
        {:noreply, put_flash(socket, :error, "Completion not found")}
    end
  end

  def handle_event("delete_qualitative", _params, socket) do
    with {:ok, habit} <- fetch_user_habit(socket.assigns.qualitative_habit_id, socket) do
      :ok = Habits.unlog_habit_completion(habit, socket.assigns.qualitative_date)
      StreakCache.invalidate(socket.assigns.current_scope.user.id, habit.id)

      {:noreply,
       socket
       |> remove_completion_from_habit(habit.id, socket.assigns.qualitative_date)
       |> assign(:show_qualitative_modal, false)
       |> assign(:qualitative_habit_id, nil)
       |> assign(:qualitative_date, nil)
       |> assign(:qualitative_is_edit, false)
       |> assign(:qualitative_modal_options, [])
       |> put_flash(:info, "Completion removed")}
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

  def handle_event("open_settings_modal", %{"id" => id}, socket) do
    with {:ok, habit} <- fetch_user_habit(id, socket) do
      {:noreply,
       socket
       |> assign(:show_settings_modal, true)
       |> assign(:settings_habit, habit)
       |> assign(:settings_tracking_mode, habit.tracking_mode)
       |> assign(:settings_qual_rows, settings_qual_rows_for_habit(habit))}
    else
      :error -> {:noreply, habit_not_found(socket)}
    end
  end

  def handle_event("close_settings_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_settings_modal, false)
     |> assign(:settings_habit, nil)
     |> assign(:settings_tracking_mode, :binary)
     |> assign(:settings_qual_rows, [])}
  end

  def handle_event("settings_select_mode", %{"mode" => mode}, socket) do
    new_mode = parse_tracking_mode(mode)
    habit = socket.assigns.settings_habit

    qual_rows =
      if new_mode == :qualitative do
        settings_qual_rows_for_habit(%{habit | tracking_mode: :qualitative})
      else
        socket.assigns.settings_qual_rows
      end

    {:noreply,
     socket
     |> assign(:settings_tracking_mode, new_mode)
     |> assign(:settings_qual_rows, qual_rows)}
  end

  def handle_event("settings_qual_add_row", _params, socket) do
    rows = socket.assigns.settings_qual_rows

    if length(rows) >= 5 do
      {:noreply, socket}
    else
      i = length(rows)

      new_row = %{
        index: i,
        id: "new-#{i}",
        color: default_qual_color_at(i),
        label: ""
      }

      {:noreply, assign(socket, :settings_qual_rows, rows ++ [new_row])}
    end
  end

  def handle_event("settings_qual_remove_row", _params, socket) do
    rows = socket.assigns.settings_qual_rows

    if length(rows) <= 2 do
      {:noreply, socket}
    else
      new_rows =
        rows
        |> Enum.take(length(rows) - 1)
        |> reindex_settings_qual_rows()

      {:noreply, assign(socket, :settings_qual_rows, new_rows)}
    end
  end

  def handle_event("save_habit_settings", params, socket) do
    habit_id = params["habit_id"]
    mode = parse_tracking_mode(params["tracking_mode"] || "binary")

    raw_opts = params["qualitative_options"] || %{}

    qualitative_options =
      raw_opts
      |> Habit.build_qualitative_options_from_params()
      |> Habit.finalize_qualitative_option_ids()

    attrs =
      cond do
        mode == :quantity ->
          %{
            tracking_mode: :quantity,
            quantity_low: parse_int(params["quantity_low"], 1),
            quantity_high: parse_int(params["quantity_high"], 10)
          }

        mode == :qualitative ->
          %{tracking_mode: :qualitative, qualitative_options: qualitative_options}

        true ->
          %{tracking_mode: :binary}
      end

    with {:ok, habit} <- fetch_user_habit(habit_id, socket),
         {:ok, _updated} <- Habits.update_habit(habit, attrs) do
      habits = Habits.list_habits(socket.assigns.current_scope.user)

      {:noreply,
       socket
       |> assign(:habits, habits)
       |> assign(:show_settings_modal, false)
       |> assign(:settings_habit, nil)
       |> assign(:settings_tracking_mode, :binary)
       |> assign(:settings_qual_rows, [])
       |> put_flash(:info, "Habit settings updated!")}
    else
      :error ->
        {:noreply, habit_not_found(socket)}

      {:error, changeset} ->
        errors = changeset.errors |> Enum.map(fn {field, {msg, _}} -> "#{field}: #{msg}" end)

        {:noreply,
         socket
         |> put_flash(:error, "Error updating settings: #{Enum.join(errors, ", ")}")}
    end
  end

  def handle_event(
        "open_weekly_note_modal",
        %{"habit_id" => habit_id, "year" => year, "week" => week},
        socket
      ) do
    year = String.to_integer(year)
    week = String.to_integer(week)
    habit_id_int = String.to_integer(habit_id)

    existing_note = Habits.get_weekly_note(habit_id_int, year, week)

    {:noreply,
     socket
     |> assign(:show_weekly_note_modal, true)
     |> assign(:weekly_note_habit_id, habit_id)
     |> assign(:weekly_note_year, year)
     |> assign(:weekly_note_week, week)
     |> assign(:weekly_note_text, if(existing_note, do: existing_note.notes || "", else: ""))
     |> assign(:weekly_note_has_existing, existing_note != nil)}
  end

  def handle_event("close_weekly_note_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_weekly_note_modal, false)
     |> assign(:weekly_note_habit_id, nil)
     |> assign(:weekly_note_year, nil)
     |> assign(:weekly_note_week, nil)
     |> assign(:weekly_note_text, "")
     |> assign(:weekly_note_has_existing, false)}
  end

  def handle_event(
        "save_weekly_note",
        %{"year" => year, "week_number" => week, "notes" => notes},
        socket
      ) do
    year = String.to_integer(year)
    week = String.to_integer(week)

    with {:ok, habit} <- fetch_user_habit(socket.assigns.weekly_note_habit_id, socket),
         {:ok, _note} <- Habits.upsert_weekly_note(habit, year, week, notes) do
      weekly_notes_by_habit =
        update_weekly_notes_cache(
          socket.assigns.weekly_notes_by_habit,
          habit.id,
          year,
          week,
          notes
        )

      {:noreply,
       socket
       |> assign(:weekly_notes_by_habit, weekly_notes_by_habit)
       |> assign(:show_weekly_note_modal, false)
       |> assign(:weekly_note_habit_id, nil)
       |> assign(:weekly_note_year, nil)
       |> assign(:weekly_note_week, nil)
       |> assign(:weekly_note_text, "")
       |> assign(:weekly_note_has_existing, false)
       |> put_flash(:info, "Note saved!")}
    else
      :error ->
        {:noreply, habit_not_found(socket)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Error saving note")}
    end
  end

  def handle_event("delete_weekly_note", _params, socket) do
    year = socket.assigns.weekly_note_year
    week = socket.assigns.weekly_note_week

    with {:ok, habit} <- fetch_user_habit(socket.assigns.weekly_note_habit_id, socket),
         note <- Habits.get_weekly_note(habit, year, week),
         true <- note != nil,
         {:ok, _} <- Habits.delete_weekly_note(note) do
      weekly_notes_by_habit =
        remove_from_weekly_notes_cache(
          socket.assigns.weekly_notes_by_habit,
          habit.id,
          year,
          week
        )

      {:noreply,
       socket
       |> assign(:weekly_notes_by_habit, weekly_notes_by_habit)
       |> assign(:show_weekly_note_modal, false)
       |> assign(:weekly_note_habit_id, nil)
       |> assign(:weekly_note_year, nil)
       |> assign(:weekly_note_week, nil)
       |> assign(:weekly_note_text, "")
       |> assign(:weekly_note_has_existing, false)
       |> put_flash(:info, "Note deleted!")}
    else
      :error ->
        {:noreply, habit_not_found(socket)}

      _ ->
        {:noreply, put_flash(socket, :error, "Error deleting note")}
    end
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
    changeset = Habit.changeset(%Habit{}, %{tracking_mode: :binary})

    socket
    |> assign(:form, to_form(changeset, as: :habit))
    |> assign(:create_qual_rows, initial_create_qual_rows(2))
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

  defp normalize_create_habit_params(habit_params, opts) do
    raw = habit_params["qualitative_options"] || %{}

    q_opts =
      raw
      |> Habit.build_qualitative_options_from_params()
      |> then(fn list ->
        if Keyword.get(opts, :finalize_qualitative_ids, false) do
          Habit.finalize_qualitative_option_ids(list)
        else
          list
        end
      end)

    Map.put(habit_params, "qualitative_options", q_opts)
  end

  defp parse_tracking_mode("binary"), do: :binary
  defp parse_tracking_mode("quantity"), do: :quantity
  defp parse_tracking_mode("qualitative"), do: :qualitative
  defp parse_tracking_mode(_), do: :binary

  defp settings_qual_rows_for_habit(%Habit{tracking_mode: :qualitative} = habit) do
    opts = habit.qualitative_options || []
    build_settings_qual_rows(opts)
  end

  defp settings_qual_rows_for_habit(%Habit{}) do
    initial_create_qual_rows(2)
  end

  defp build_settings_qual_rows(opts) when is_list(opts) do
    n =
      cond do
        opts == [] ->
          2

        length(opts) == 1 ->
          2

        true ->
          min(5, max(2, length(opts)))
      end

    for i <- 0..(n - 1) do
      case Enum.at(opts, i) do
        nil ->
          %{index: i, id: "new-#{i}", color: default_qual_color_at(i), label: ""}

        o when is_map(o) ->
          id = Map.get(o, "id") || Map.get(o, :id) || "new-#{i}"
          color = Map.get(o, "color") || Map.get(o, :color) || default_qual_color_at(i)
          label = Map.get(o, "label") || Map.get(o, :label) || ""
          %{index: i, id: id, color: normalize_hex_color(color), label: label}
      end
    end
  end

  defp reindex_settings_qual_rows(rows) do
    rows
    |> Enum.with_index()
    |> Enum.map(fn {row, i} ->
      color = Map.get(row, :color) || Map.get(row, "color") || default_qual_color_at(i)
      label = Map.get(row, :label) || Map.get(row, "label") || ""
      raw_id = Map.get(row, :id) || Map.get(row, "id")

      id =
        cond do
          is_binary(raw_id) and raw_id != "" and not String.starts_with?(raw_id, "new-") ->
            raw_id

          true ->
            "new-#{i}"
        end

      %{index: i, id: id, color: normalize_hex_color(color), label: label}
    end)
  end

  defp initial_create_qual_rows(count) when count in 2..5 do
    for i <- 0..(count - 1) do
      %{index: i, id: "new-#{i}", color: default_qual_color_at(i), label: ""}
    end
  end

  defp default_qual_color_at(i) do
    ~w(#dc2626 #ea580c #eab308 #16a34a #2563eb)
    |> Enum.at(i, "#6b7280")
  end

  defp build_create_qual_rows_from_params(raw_qual, fallback_rows) do
    parsed =
      case raw_qual do
        %{} = m when map_size(m) > 0 ->
          m
          |> Enum.reject(fn {k, _} -> k in [nil, ""] end)
          |> Enum.sort_by(fn {k, _} -> qual_form_key_to_int(k) end)
          |> Enum.map(fn {_k, fields} ->
            f = stringify_qual_fields(fields)
            color = Map.get(f, "color", "#6b7280") |> normalize_hex_color()
            label = Map.get(f, "label", "") |> to_string()
            %{color: color, label: label}
          end)

        _ ->
          []
      end

    rows =
      if parsed == [] do
        fallback_rows
        |> List.wrap()
        |> then(fn fb ->
          if length(fb) >= 2 do
            reindex_new_habit_qual_rows(fb)
          else
            initial_create_qual_rows(2)
          end
        end)
      else
        parsed
        |> Enum.with_index()
        |> Enum.map(fn {r, i} ->
          %{index: i, id: "new-#{i}", color: r.color, label: r.label}
        end)
        |> Enum.take(5)
      end

    if length(rows) < 2, do: initial_create_qual_rows(2), else: rows
  end

  defp qual_form_key_to_int(k) do
    case Integer.parse(to_string(k)) do
      {i, _} -> i
      :error -> 0
    end
  end

  defp stringify_qual_fields(fields) when is_map(fields) do
    Map.new(fields, fn {k, v} -> {to_string(k), v} end)
  end

  defp normalize_hex_color(color) when is_binary(color) do
    c = color |> String.trim() |> String.downcase()

    cond do
      c == "" ->
        "#6b7280"

      String.starts_with?(c, "#") and String.length(c) == 7 ->
        c

      String.starts_with?(c, "#") ->
        c

      true ->
        "#" <> c
    end
  end

  defp normalize_hex_color(_), do: "#6b7280"

  defp reindex_new_habit_qual_rows(rows) do
    rows
    |> Enum.with_index()
    |> Enum.map(fn {row, i} ->
      color = Map.get(row, :color) || Map.get(row, "color") || default_qual_color_at(i)
      label = Map.get(row, :label) || Map.get(row, "label") || ""

      %{index: i, id: "new-#{i}", color: normalize_hex_color(color), label: label}
    end)
  end

  defp parse_int(nil, default), do: default
  defp parse_int("", default), do: default

  defp parse_int(value, default) when is_binary(value) do
    case Integer.parse(value) do
      {int, _} -> int
      :error -> default
    end
  end

  defp load_weekly_notes_for_habits(habits, timezone) do
    # Get the year/week pairs for visible weeks (last 52 weeks)
    year_week_pairs = get_visible_year_week_pairs(timezone)

    habits
    |> Enum.map(fn habit ->
      notes_map = Habits.get_weekly_notes_map(habit.id, year_week_pairs)
      {habit.id, notes_map}
    end)
    |> Map.new()
  end

  defp get_visible_year_week_pairs(timezone) do
    today = Habits.today(timezone)

    # Get dates for the last 52 weeks (matching the grid display)
    0..51
    |> Enum.map(fn weeks_ago ->
      date = Date.add(today, -weeks_ago * 7)
      :calendar.iso_week_number(Date.to_erl(date))
    end)
    |> Enum.uniq()
  end

  defp update_weekly_notes_cache(weekly_notes_by_habit, habit_id, year, week, notes) do
    habit_notes = Map.get(weekly_notes_by_habit, habit_id, %{})

    updated_habit_notes =
      if notes == "" do
        Map.delete(habit_notes, {year, week})
      else
        Map.put(habit_notes, {year, week}, %{notes: notes})
      end

    Map.put(weekly_notes_by_habit, habit_id, updated_habit_notes)
  end

  defp remove_from_weekly_notes_cache(weekly_notes_by_habit, habit_id, year, week) do
    habit_notes = Map.get(weekly_notes_by_habit, habit_id, %{})
    updated_habit_notes = Map.delete(habit_notes, {year, week})
    Map.put(weekly_notes_by_habit, habit_id, updated_habit_notes)
  end
end
