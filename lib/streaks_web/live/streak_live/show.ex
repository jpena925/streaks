defmodule StreaksWeb.StreakLive.Show do
  use StreaksWeb, :live_view

  alias Streaks.Habits

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:streak, Habits.get_streak!(id))}
  end

  defp page_title(:show), do: "Show Streak"
  defp page_title(:edit), do: "Edit Streak"
end
