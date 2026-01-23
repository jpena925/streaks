defmodule StreaksWeb.HabitsLive.WeeklyNoteModal do
  use StreaksWeb, :html

  alias Streaks.Habits

  attr :show, :boolean, required: true
  attr :year, :integer, default: nil
  attr :week_number, :integer, default: nil
  attr :notes, :string, default: ""
  attr :has_existing_note, :boolean, default: false

  def weekly_note_modal(assigns) do
    {start_date, end_date} =
      if assigns.year && assigns.week_number do
        Habits.week_date_range(assigns.year, assigns.week_number)
      else
        {nil, nil}
      end

    assigns =
      assigns
      |> assign(:start_date, start_date)
      |> assign(:end_date, end_date)

    ~H"""
    <div
      :if={@show}
      class="fixed inset-0 z-50 overflow-y-auto"
      phx-window-keydown="close_weekly_note_modal"
      phx-key="Escape"
    >
      <!-- Backdrop -->
      <div
        class="fixed inset-0 bg-black bg-opacity-50 transition-opacity"
        phx-click="close_weekly_note_modal"
      >
      </div>
      
    <!-- Modal -->
      <div class="flex min-h-full items-center justify-center p-4">
        <div class="relative bg-white dark:bg-gray-800 rounded border border-gray-200 dark:border-gray-700 max-w-lg w-full p-6">
          <h3 class="text-xl font-bold text-gray-900 dark:text-white mb-1">
            Week {@week_number} Notes
          </h3>
          <p class="text-sm text-gray-500 dark:text-gray-400 mb-4">
            {format_date(@start_date)} – {format_date(@end_date)}
          </p>

          <form phx-submit="save_weekly_note" class="space-y-4">
            <input type="hidden" name="year" value={@year} />
            <input type="hidden" name="week_number" value={@week_number} />

            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Notes
              </label>
              <textarea
                name="notes"
                rows="5"
                autofocus
                class="w-full px-4 py-3 border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-900 dark:text-white rounded focus:outline-none focus:ring-2 focus:ring-green-500 dark:focus:ring-green-400 focus:border-transparent transition-colors text-base resize-none"
                placeholder="Add notes about this week..."
              >{@notes}</textarea>
            </div>

            <div class="flex gap-3">
              <.primary_button type="submit" class="flex-1">
                Save
              </.primary_button>
              <button
                type="button"
                phx-click="close_weekly_note_modal"
                class="flex-1 bg-gray-100 hover:bg-gray-200 dark:bg-gray-700 dark:hover:bg-gray-600 text-gray-700 dark:text-gray-300 font-semibold px-6 py-3 rounded transition-colors duration-200"
              >
                Cancel
              </button>
            </div>

            <div :if={@has_existing_note} class="border-t border-gray-200 dark:border-gray-700 pt-4">
              <button
                type="button"
                phx-click="delete_weekly_note"
                data-confirm="Are you sure you want to delete this note?"
                class="w-full bg-red-100 hover:bg-red-200 dark:bg-red-900/30 dark:hover:bg-red-900/50 text-red-700 dark:text-red-400 font-semibold px-6 py-3 rounded transition-colors duration-200 flex items-center justify-center gap-2"
              >
                <.icon name="hero-trash" class="w-5 h-5" /> Delete Note
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
    """
  end

  defp format_date(nil), do: ""

  defp format_date(date) do
    Calendar.strftime(date, "%b %d, %Y")
  end
end
