defmodule StreaksWeb.StreakLive.GridComponent do
  use StreaksWeb, :live_component

  @doc """
  Renders a grid for the streak, one square per day in the year (7 columns x ~52 rows).
  Each square is clickable and cycles through grey (default), green (done), red (missed).
  The state is kept in the days map, where keys are ISO dates ("YYYY-MM-DD") and values are "none", "done", or "missed".
  """
  def render(assigns) do
    ~H"""
    <div class="streak-card">
      <h3 class="streak-title">{@streak.name}</h3>
      <div class="streak-grid" style="display: flex; flex-direction: row; gap: 2px;">
        <%= for week <- build_weeks(@streak.year, @streak.days) do %>
          <div class="week" style="display: flex; flex-direction: column; gap: 2px;">
            <%= for {date, status} <- week do %>
              <div
                phx-click="toggle_day"
                phx-value-date={date}
                phx-target={@myself}
                class={day_class(status)}
                style="width: 16px; height: 16px; border-radius: 2px; cursor: pointer; border: 1px solid #ccc;"
                title={date}
              >
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
      <div class="streak-counter" style="margin-top: 8px;">
        {streak_count(@streak.days)} days into your streak!
      </div>
      <button phx-click="reset_days" phx-target={@myself} class="reset-btn" style="margin-top: 8px;">
        Reset
      </button>
    </div>
    """
  end

  def handle_event("toggle_day", %{"date" => date}, socket) do
    days =
      Map.put(
        socket.assigns.streak.days || %{},
        date,
        next_status(Map.get(socket.assigns.streak.days || %{}, date, "none"))
      )

    send(self(), {:update_days, socket.assigns.streak.id, days})
    {:noreply, assign(socket, streak: %{socket.assigns.streak | days: days})}
  end

  def handle_event("reset_days", _params, socket) do
    days =
      (socket.assigns.streak.days || %{})
      |> Map.keys()
      |> Enum.map(&{&1, "none"})
      |> Enum.into(%{})

    send(self(), {:update_days, socket.assigns.streak.id, days})
    {:noreply, socket}
  end

  # Helpers
  defp build_weeks(year, days) do
    start_date = Date.new!(year, 1, 1)
    end_date = Date.new!(year, 12, 31)

    all_days =
      Enum.map(Date.range(start_date, end_date), fn date ->
        {Date.to_iso8601(date), Map.get(days || %{}, Date.to_iso8601(date), "none")}
      end)

    Enum.chunk_every(all_days, 7)
  end

  defp day_class("none"), do: "day day-none"
  defp day_class("done"), do: "day day-done"
  defp day_class("missed"), do: "day day-missed"
  defp day_class(_), do: "day day-none"

  defp next_status("none"), do: "done"
  defp next_status("done"), do: "missed"
  defp next_status("missed"), do: "none"
  defp next_status(_), do: "done"

  defp streak_count(days) do
    days = days || %{}
    sorted = Enum.sort_by(days, fn {date, _} -> date end)

    sorted
    |> Enum.reverse()
    |> Enum.reduce_while(0, fn {_, status}, acc ->
      if status == "done" do
        {:cont, acc + 1}
      else
        {:halt, acc}
      end
    end)
  end
end
