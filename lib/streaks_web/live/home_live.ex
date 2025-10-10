defmodule StreaksWeb.HomeLive do
  use StreaksWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex flex-col items-center justify-center bg-gray-50 dark:bg-gray-900">
      <div class="text-center flex flex-col gap-4">
        <h2 class="text-4xl font-bold text-gray-900 dark:text-white mb-8">Streaks</h2>

        <div :if={@current_scope && @current_scope.user}>
          <!-- Authenticated user content -->
          <div class="space-y-4">
            <p class="text-lg text-gray-600 dark:text-gray-300">
              Welcome back, {@current_scope.user.email}!
            </p>
            <.link
              href={~p"/streaks"}
              class="inline-block bg-blue-600 hover:bg-blue-700 dark:bg-blue-500 dark:hover:bg-blue-600 text-white font-medium py-3 px-6 rounded-lg transition-colors duration-200"
            >
              View Your Streaks
            </.link>
            <.link
              href={~p"/users/settings"}
              class="inline-block bg-gray-600 hover:bg-gray-700 dark:bg-gray-700 dark:hover:bg-gray-600 text-white font-medium py-3 px-6 rounded-lg transition-colors duration-200 ml-4"
            >
              Settings
            </.link>
          </div>
        </div>

        <div :if={!@current_scope || !@current_scope.user}>
          <!-- Non-authenticated user content -->
          <div class="space-y-4">
            <p class="text-lg text-gray-600 dark:text-gray-300 mb-6">
              Track your habits and see what you've done
            </p>
            <.link
              href={~p"/users/register"}
              class="inline-block bg-blue-600 hover:bg-blue-700 dark:bg-blue-500 dark:hover:bg-blue-600 text-white font-medium py-3 px-6 rounded-lg transition-colors duration-200"
            >
              Get Started
            </.link>
            <.link
              href={~p"/users/log-in"}
              class="inline-block bg-gray-600 hover:bg-gray-700 dark:bg-gray-700 dark:hover:bg-gray-600 text-white font-medium py-3 px-6 rounded-lg transition-colors duration-200 ml-4"
            >
              Log In
            </.link>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
