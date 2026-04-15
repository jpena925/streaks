defmodule StreaksWeb.HabitsLive.QualitativeModal do
  use StreaksWeb, :html

  attr :show, :boolean, required: true
  attr :options, :list, default: []
  attr :is_edit_mode, :boolean, default: false

  def qualitative_modal(assigns) do
    ~H"""
    <div
      :if={@show}
      class="fixed inset-0 z-50 overflow-y-auto"
      phx-window-keydown="close_qualitative_modal"
      phx-key="Escape"
    >
      <div
        class="fixed inset-0 bg-black bg-opacity-50 transition-opacity"
        phx-click="close_qualitative_modal"
      >
      </div>

      <div class="flex min-h-full items-center justify-center p-4">
        <div class="relative bg-white dark:bg-gray-800 rounded border border-gray-200 dark:border-gray-700 max-w-md w-full p-6">
          <h3 class="text-xl font-bold text-gray-900 dark:text-white mb-1">
            {if(@is_edit_mode, do: "Update mood", else: "How did it go?")}
          </h3>
          <p class="text-sm text-gray-500 dark:text-gray-400 mb-4">
            Tap a color to log this day.
          </p>

          <div class="flex flex-wrap gap-3 justify-center">
            <button
              :for={opt <- @options}
              type="button"
              phx-click="submit_qualitative"
              phx-value-option_id={opt["id"] || opt[:id]}
              class="w-14 h-14 rounded-lg border-2 border-black/10 dark:border-white/10 shadow-sm hover:scale-105 active:scale-95 transition-transform focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-900 dark:focus:ring-white"
              style={"background-color: #{opt["color"] || opt[:color]}"}
            >
            </button>
          </div>

          <div class="flex gap-3 mt-6">
            <button
              type="button"
              phx-click="close_qualitative_modal"
              class="flex-1 bg-gray-100 hover:bg-gray-200 dark:bg-gray-700 dark:hover:bg-gray-600 text-gray-700 dark:text-gray-300 font-semibold px-6 py-3 rounded transition-colors duration-200"
            >
              Cancel
            </button>
            <button
              :if={@is_edit_mode}
              type="button"
              phx-click="delete_qualitative"
              class="flex-1 bg-red-50 hover:bg-red-100 dark:bg-red-950/40 dark:hover:bg-red-950/60 text-red-700 dark:text-red-300 font-semibold px-6 py-3 rounded transition-colors duration-200"
            >
              Remove
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
