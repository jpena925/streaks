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
        "w-5 h-5 sm:w-3.5 sm:h-3.5 rounded-sm border-2 transition-colors duration-200 relative group touch-manipulation",
        if(@is_future,
          do: "bg-gray-100 dark:bg-gray-700 cursor-not-allowed opacity-30 border-transparent",
          else: "cursor-pointer hover:opacity-80 active:scale-95"
        ),
        if(!@is_future && @completed, do: @completed_classes, else: nil),
        if(!@is_future && !@completed,
          do:
            "bg-gray-200 dark:bg-gray-700 hover:bg-gray-300 dark:hover:bg-gray-600 border-transparent hover:border-gray-400 dark:hover:border-gray-500",
          else: nil
        ),
        if(@is_today,
          do: "ring-2 ring-green-500 dark:ring-green-400 ring-offset-1 dark:ring-offset-gray-900",
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
      phx-hook={get_hook(@is_future, @quantity, @completed)}
      data-tooltip-text={if(@quantity && @completed, do: "#{@quantity}", else: nil)}
      data-habit-id={@habit_id}
      data-date={Date.to_iso8601(@date)}
    >
    </div>
    """
  end

  defp get_hook(true, _quantity, _completed), do: nil
  defp get_hook(_is_future, quantity, true) when not is_nil(quantity), do: "Tooltip"
  defp get_hook(_is_future, _quantity, _completed), do: "Touch"

  defp quantity_intensity_class(nil, _low, _high) do
    "bg-green-500 border-transparent shadow-sm"
  end

  defp quantity_intensity_class(quantity, low, high) do
    level = intensity_level(quantity, low, high)

    case level do
      1 -> "bg-green-300 border-transparent shadow-sm"
      2 -> "bg-green-400 border-transparent shadow-sm"
      3 -> "bg-green-500 border-transparent shadow-sm"
      4 -> "bg-green-600 border-transparent shadow-sm"
      _ -> "bg-green-700 border-transparent shadow-sm"
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
