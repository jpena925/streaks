defmodule StreaksWeb.HabitsLive.HabitCube do
  use StreaksWeb, :html

  attr :date, Date, required: true
  attr :completed, :boolean, required: true
  attr :quantity, :integer, default: nil
  attr :habit_id, :integer, required: true
  attr :is_today, :boolean, default: false
  attr :is_future, :boolean, default: false
  attr :has_quantity, :boolean, default: false
  attr :quantity_low, :integer, default: 1
  attr :quantity_high, :integer, default: 10

  def habit_cube(assigns) do
    title = Date.to_iso8601(assigns.date)

    completed_classes =
      quantity_intensity_class(assigns.quantity, assigns.quantity_low, assigns.quantity_high)

    assigns =
      assigns
      |> assign(:title, title)
      |> assign(:completed_classes, completed_classes)

    ~H"""
    <div
      id={"habit-cube-#{@habit_id}-#{Date.to_iso8601(@date)}"}
      class={[
        "w-5 h-5 sm:w-3.5 sm:h-3.5 rounded-sm border transition-all duration-200 relative group touch-manipulation",
        if(@is_future,
          do:
            "bg-gray-200/50 dark:bg-gray-800/50 cursor-not-allowed opacity-50 border-gray-300 dark:border-gray-700",
          else: "cursor-pointer hover:opacity-80 active:scale-95"
        ),
        if(!@is_future && @completed,
          do: [
            @completed_classes,
            "habit-cube-complete",
            if(@is_today, do: "habit-cube-today", else: nil)
          ],
          else: nil
        ),
        if(!@is_future && !@completed,
          do:
            "bg-gray-200 dark:bg-gray-800 border-gray-400 dark:border-gray-600 hover:bg-gray-300 dark:hover:bg-gray-700 hover:border-gray-500 dark:hover:border-gray-500",
          else: nil
        ),
        if(@is_today && !@completed,
          do:
            "ring-2 ring-orange-500 dark:ring-orange-400 ring-offset-1 ring-offset-gray-50 dark:ring-offset-black",
          else: nil
        ),
        if(@is_today && @completed,
          do:
            "ring-2 ring-green-400 dark:ring-green-300 ring-offset-1 ring-offset-gray-50 dark:ring-offset-black",
          else: nil
        )
      ]}
      title={if(@quantity && @completed, do: nil, else: @title)}
      phx-click={
        cond do
          @is_future -> nil
          @completed && @has_quantity -> "edit_quantity"
          @completed -> "unlog_day"
          true -> "log_day"
        end
      }
      phx-value-habit_id={@habit_id}
      phx-value-date={Date.to_iso8601(@date)}
      phx-hook={if(@quantity && @completed, do: "Tooltip", else: nil)}
      data-tooltip-text={if(@quantity && @completed, do: "#{@quantity}", else: nil)}
    >
    </div>
    """
  end

  defp quantity_intensity_class(nil, _low, _high) do
    "bg-green-500 dark:bg-green-500 border-green-600 dark:border-green-400"
  end

  defp quantity_intensity_class(quantity, low, high) do
    level = intensity_level(quantity, low, high)

    case level do
      1 -> "bg-green-400/70 dark:bg-green-600/60 border-green-500 dark:border-green-500"
      2 -> "bg-green-400 dark:bg-green-500/70 border-green-500 dark:border-green-400"
      3 -> "bg-green-500 dark:bg-green-500 border-green-600 dark:border-green-400"
      4 -> "bg-green-600 dark:bg-green-400 border-green-700 dark:border-green-300"
      _ -> "bg-green-700 dark:bg-green-300 border-green-800 dark:border-green-200"
    end
  end

  defp intensity_level(quantity, low, high) when high > low do
    range = high - low

    cond do
      quantity <= low ->
        1

      quantity >= high ->
        5

      true ->
        normalized = (quantity - low) / range
        trunc(normalized * 4) + 1
    end
  end

  defp intensity_level(_quantity, _low, _high), do: 3
end
