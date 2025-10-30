defmodule StreaksWeb.HomeLive do
  use StreaksWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex flex-col items-center justify-center bg-white dark:bg-black">
      <div class="text-center flex flex-col gap-4">
        <h2 class="text-3xl font-normal text-gray-900 dark:text-white mb-6">streaks</h2>

        <div :if={@current_scope && @current_scope.user}>
          <!-- Authenticated user content -->
          <div class="space-y-4">
            <p class="text-sm text-gray-600 dark:text-gray-400">
              Welcome back, {@current_scope.user.email}
            </p>
            <div class="flex gap-2 justify-center mt-6">
              <.link
                href={~p"/streaks"}
                class="inline-block border border-gray-900 dark:border-gray-100 text-gray-900 dark:text-gray-100 hover:bg-gray-900 hover:text-white dark:hover:bg-gray-100 dark:hover:text-gray-900 px-4 py-2 transition-colors text-sm"
              >
                View Your Streaks
              </.link>
              <.link
                href={~p"/users/settings"}
                class="inline-block border border-gray-300 dark:border-gray-700 text-gray-600 dark:text-gray-400 hover:border-gray-900 dark:hover:border-gray-100 px-4 py-2 transition-colors text-sm"
              >
                Settings
              </.link>
            </div>
          </div>
        </div>

        <div :if={!@current_scope || !@current_scope.user}>
          <!-- Non-authenticated user content -->
          <div class="space-y-4">
            <p class="text-sm text-gray-600 dark:text-gray-400 mb-6">
              Track your habits and see what you've done
            </p>
            <div class="flex gap-2 justify-center">
              <.link
                href={~p"/users/register"}
                class="inline-block border border-gray-900 dark:border-gray-100 text-gray-900 dark:text-gray-100 hover:bg-gray-900 hover:text-white dark:hover:bg-gray-100 dark:hover:text-gray-900 px-4 py-2 transition-colors text-sm"
              >
                Get Started
              </.link>
              <.link
                href={~p"/users/log-in"}
                class="inline-block border border-gray-300 dark:border-gray-700 text-gray-600 dark:text-gray-400 hover:border-gray-900 dark:hover:border-gray-100 px-4 py-2 transition-colors text-sm"
              >
                Log In
              </.link>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
