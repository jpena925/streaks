defmodule StreaksWeb.HabitsLive.HabitSettingsModal do
  use StreaksWeb, :html

  attr :show, :boolean, required: true
  attr :habit, :map, default: nil
  attr :tracking_mode, :atom, default: :binary
  attr :qual_rows, :list, default: []

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
        <div class="relative bg-white dark:bg-gray-800 rounded border border-gray-200 dark:border-gray-700 max-w-md w-full p-6 max-h-[90vh] overflow-y-auto">
          <h3 class="text-xl font-bold text-gray-900 dark:text-white mb-1">
            Habit Settings
          </h3>
          <p class="text-sm text-gray-500 dark:text-gray-400 mb-4">
            {@habit.name}
          </p>

          <form phx-submit="save_habit_settings" id="habit-settings-form" class="space-y-4">
            <input type="hidden" name="habit_id" value={@habit.id} />

            <fieldset class="space-y-2">
              <legend class="text-sm font-medium text-gray-900 dark:text-white">
                How do you track this?
              </legend>
              <label class="flex items-center gap-3 cursor-pointer">
                <input
                  type="radio"
                  name="tracking_mode"
                  value="binary"
                  checked={@tracking_mode == :binary}
                  phx-click="settings_select_mode"
                  phx-value-mode="binary"
                  class="w-4 h-4 border-gray-300 dark:border-gray-600 text-green-600"
                />
                <span class="text-sm text-gray-800 dark:text-gray-200">Yes / no</span>
              </label>
              <label class="flex items-center gap-3 cursor-pointer">
                <input
                  type="radio"
                  name="tracking_mode"
                  value="quantity"
                  checked={@tracking_mode == :quantity}
                  phx-click="settings_select_mode"
                  phx-value-mode="quantity"
                  class="w-4 h-4 border-gray-300 dark:border-gray-600 text-green-600"
                />
                <span class="text-sm text-gray-800 dark:text-gray-200">
                  Number (gradient by amount)
                </span>
              </label>
              <label class="flex items-center gap-3 cursor-pointer">
                <input
                  type="radio"
                  name="tracking_mode"
                  value="qualitative"
                  checked={@tracking_mode == :qualitative}
                  phx-click="settings_select_mode"
                  phx-value-mode="qualitative"
                  class="w-4 h-4 border-gray-300 dark:border-gray-600 text-green-600"
                />
                <span class="text-sm text-gray-800 dark:text-gray-200">Qualitative (colors)</span>
              </label>
            </fieldset>

            <div
              :if={@tracking_mode == :quantity}
              class="pl-2 space-y-3 border-l-2 border-gray-200 dark:border-gray-700"
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

            <div
              :if={@tracking_mode == :qualitative}
              class="pl-2 space-y-3 border-l-2 border-gray-200 dark:border-gray-700"
            >
              <p class="text-xs text-gray-500 dark:text-gray-500">
                Use 2–5 colors. Meanings stay here for your reference when logging uses colors only.
              </p>
              <div :for={row <- @qual_rows} class="flex flex-col sm:flex-row gap-2 sm:items-end">
                <input type="hidden" name={"qualitative_options[#{row.index}][id]"} value={row.id} />
                <div class="flex items-center gap-2">
                  <label class="text-xs text-gray-500 dark:text-gray-400 sr-only">Color</label>
                  <input
                    type="color"
                    name={"qualitative_options[#{row.index}][color]"}
                    value={row.color}
                    class="h-10 w-14 rounded border border-gray-300 dark:border-gray-600 cursor-pointer bg-white dark:bg-gray-700"
                  />
                </div>
                <div class="flex-1">
                  <label class="text-xs text-gray-400 dark:text-gray-600 block mb-1">
                    Meaning (setup only)
                  </label>
                  <input
                    type="text"
                    name={"qualitative_options[#{row.index}][label]"}
                    value={row.label}
                    placeholder="e.g. Rough day"
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-900 dark:text-white placeholder-gray-400 dark:placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-green-500 rounded text-sm"
                  />
                </div>
              </div>
              <div class="flex flex-wrap items-center gap-2 pt-1">
                <button
                  type="button"
                  phx-click="settings_qual_add_row"
                  disabled={length(@qual_rows) >= 5}
                  class={[
                    "inline-flex items-center gap-1.5 px-2.5 py-1.5 rounded text-xs font-medium border transition-colors",
                    if(length(@qual_rows) >= 5,
                      do:
                        "opacity-40 cursor-not-allowed border-gray-200 dark:border-gray-700 text-gray-400",
                      else:
                        "border-gray-300 dark:border-gray-600 text-gray-800 dark:text-gray-200 hover:border-gray-900 dark:hover:border-gray-400"
                    )
                  ]}
                >
                  <.icon name="hero-plus" class="w-3.5 h-3.5" /> Add level
                </button>
                <button
                  type="button"
                  phx-click="settings_qual_remove_row"
                  disabled={length(@qual_rows) <= 2}
                  class={[
                    "inline-flex items-center gap-1.5 px-2.5 py-1.5 rounded text-xs font-medium border transition-colors",
                    if(length(@qual_rows) <= 2,
                      do:
                        "opacity-40 cursor-not-allowed border-gray-200 dark:border-gray-700 text-gray-400",
                      else:
                        "border-gray-300 dark:border-gray-600 text-gray-600 dark:text-gray-400 hover:border-gray-900 dark:hover:border-gray-400"
                    )
                  ]}
                >
                  <.icon name="hero-minus" class="w-3.5 h-3.5" /> Remove last
                </button>
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
