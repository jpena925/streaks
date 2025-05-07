defmodule StreaksWeb.StreakLive.Index do
  use StreaksWeb, :live_view

  alias Streaks.Habits
  alias Streaks.Habits.Streak

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :streaks, Habits.list_streaks())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Streak")
    |> assign(:streak, Habits.get_streak!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Streak")
    |> assign(:streak, %Streak{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Streaks")
    |> assign(:streak, nil)
  end

  @impl true
  def handle_info({StreaksWeb.StreakLive.FormComponent, {:saved, streak}}, socket) do
    {:noreply, stream_insert(socket, :streaks, streak, at: -1)}
  end

  def handle_info({:update_days, streak_id, days}, socket) do
    streak = Habits.get_streak!(streak_id)
    {:ok, _updated_streak} = Habits.update_streak(streak, %{days: days})
    {:noreply, stream(socket, :streaks, Habits.list_streaks())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    streak = Habits.get_streak!(id)
    {:ok, _} = Habits.delete_streak(streak)

    {:noreply, stream_delete(socket, :streaks, streak)}
  end
end
