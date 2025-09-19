defmodule StreaksWeb.HabitsLive.Habits do
  use StreaksWeb, :live_view

  def render(assigns) do
    ~H"""
    <div>
      <h1>Streaks</h1>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end
end
