defmodule StreaksWeb.HabitsLive.QuantityModal do
  use StreaksWeb, :html

  attr :show, :boolean, required: true
  attr :quantity_value, :string, default: ""

  def quantity_modal(assigns) do
    ~H"""
    <div
      :if={@show}
      class="fixed inset-0 z-50 overflow-y-auto"
      phx-window-keydown="close_quantity_modal"
      phx-key="Escape"
    >
      <!-- Backdrop -->
      <div
        class="fixed inset-0 bg-black bg-opacity-50 transition-opacity"
        phx-click="close_quantity_modal"
      >
      </div>

    <!-- Modal -->
      <div class="flex min-h-full items-center justify-center p-4">
        <div class="relative bg-white dark:bg-gray-800 rounded border border-gray-200 dark:border-gray-700 max-w-md w-full p-6">
          <h3 class="text-xl font-bold text-gray-900 dark:text-white mb-4">
            Enter Quantity
          </h3>

          <form phx-submit="submit_quantity" class="space-y-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Quantity
              </label>
              <input
                type="number"
                name="quantity"
                value={@quantity_value}
                min="1"
                step="1"
                autofocus
                required
                class="w-full px-4 py-3 border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-900 dark:text-white rounded focus:outline-none focus:ring-2 focus:ring-green-500 dark:focus:ring-green-400 focus:border-transparent transition-colors text-base"
                placeholder="e.g., 5"
              />
            </div>

            <div class="flex gap-3">
              <.primary_button type="submit" class="flex-1">
                Save
              </.primary_button>
              <button
                type="button"
                phx-click="close_quantity_modal"
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
