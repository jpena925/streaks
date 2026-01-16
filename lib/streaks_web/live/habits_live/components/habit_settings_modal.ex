defmodule StreaksWeb.HabitsLive.HabitSettingsModal do
  use StreaksWeb, :html

  attr :show, :boolean, required: true
  attr :habit, :map, default: nil
  attr :has_quantity, :boolean, default: false

  def habit_settings_modal(assigns) do
    ~H"""
    <div
      :if={@show && @habit}
      class="fixed inset-0 z-50 overflow-y-auto"
      phx-window-keydown="close_settings_modal"
      phx-key="Escape"
    >
      <!-- Backdrop -->
      <div
        class="fixed inset-0 bg-black bg-opacity-50 transition-opacity"
        phx-click="close_settings_modal"
      >
      </div>

    <!-- Modal -->
      <div class="flex min-h-full items-center justify-center p-4">
        <div class="relative bg-white dark:bg-gray-800 rounded border border-gray-200 dark:border-gray-700 max-w-md w-full p-6">
          <h3 class="text-xl font-bold text-gray-900 dark:text-white mb-1">
            Habit Settings
          </h3>
          <p class="text-sm text-gray-500 dark:text-gray-400 mb-4">
            {@habit.name}
          </p>

          <form phx-submit="save_habit_settings" id="habit-settings-form" class="space-y-4">
            <input type="hidden" name="habit_id" value={@habit.id} />

            <label class="flex items-center gap-3 cursor-pointer group">
              <input
                type="checkbox"
                name="has_quantity"
                value="true"
                checked={@has_quantity}
                phx-click="toggle_settings_quantity"
                class="w-5 h-5 border-gray-300 dark:border-gray-600 text-green-600 focus:ring-green-500 bg-white dark:bg-gray-700 rounded cursor-pointer"
              />
              <div>
                <span class="text-sm font-medium text-gray-900 dark:text-white">
                  Track with quantity
                </span>
                <p class="text-xs text-gray-500 dark:text-gray-400">
                  Log a number instead of just checking off
                </p>
              </div>
            </label>

            <div
              :if={@has_quantity}
              class="pl-8 space-y-3 border-l-2 border-gray-200 dark:border-gray-700"
            >
              <p class="text-xs text-gray-500 dark:text-gray-500">
                Set the range for color intensity
              </p>
              <div class="flex gap-3 items-center">
                <div class="flex-1">
                  <label class="text-xs text-gray-400 dark:text-gray-600 block mb-1">
                    Low
                  </label>
                  <input
                    type="number"
                    name="quantity_low"
                    value={@habit.quantity_low || 1}
                    min="1"
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-900 dark:text-white placeholder-gray-400 dark:placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-green-500 dark:focus:ring-green-400 focus:border-transparent rounded transition-colors text-sm"
                  />
                  <span class="text-xs text-gray-400 dark:text-gray-600">Lightest shade</span>
                </div>
                <span class="text-gray-400 dark:text-gray-600 pt-4">→</span>
                <div class="flex-1">
                  <label class="text-xs text-gray-400 dark:text-gray-600 block mb-1">
                    High
                  </label>
                  <input
                    type="number"
                    name="quantity_high"
                    value={@habit.quantity_high || 10}
                    min="1"
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-900 dark:text-white placeholder-gray-400 dark:placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-green-500 dark:focus:ring-green-400 focus:border-transparent rounded transition-colors text-sm"
                  />
                  <span class="text-xs text-gray-400 dark:text-gray-600">Darkest shade</span>
                </div>
              </div>
            </div>

            <div class="flex gap-3 pt-2">
              <.primary_button type="submit" class="flex-1">
                Save Settings
              </.primary_button>
              <button
                type="button"
                phx-click="close_settings_modal"
                class="flex-1 bg-gray-100 hover:bg-gray-200 dark:bg-gray-700 dark:hover:bg-gray-600 text-gray-700 dark:text-gray-300 font-semibold px-6 py-3 rounded transition-colors duration-200"
              >
                Cancel
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
    """
  end
end
