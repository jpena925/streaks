defmodule StreaksWeb.HabitsLive.HabitCube do
  use StreaksWeb, :html

  attr :date, Date, required: true
  attr :completed, :boolean, required: true
  attr :quantity, :integer, default: nil
  attr :habit_id, :integer, required: true
  attr :is_today, :boolean, default: false
  attr :is_future, :boolean, default: false
  attr :has_quantity, :boolean, default: false

  def habit_cube(assigns) do
    title = Date.to_iso8601(assigns.date)

    completed_classes =
      if assigns.quantity do
        cond do
          assigns.quantity <= 2 ->
            "bg-green-300 border-transparent shadow-sm"

          assigns.quantity <= 5 ->
            "bg-green-500 border-transparent shadow-sm"

          assigns.quantity <= 8 ->
            "bg-green-700 border-transparent shadow-sm"

          true ->
            # 9+
            "bg-green-800 border-transparent shadow-sm"
        end
      else
        "bg-green-500 border-transparent shadow-sm"
      end

    assigns =
      assigns
      |> assign(:title, title)
      |> assign(:completed_classes, completed_classes)

    ~H"""
    <div
      id={"habit-cube-#{@habit_id}-#{Date.to_iso8601(@date)}"}
      class={[
        "w-3.5 h-3.5 rounded-sm border-2 transition-colors duration-200 relative group",
        if(@is_future,
          do: "bg-gray-100 dark:bg-gray-700 cursor-not-allowed opacity-30 border-transparent",
          else: "cursor-pointer hover:opacity-80"
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
      phx-hook={if(@quantity && @completed, do: "Tooltip", else: nil)}
      data-tooltip-text={if(@quantity && @completed, do: "#{@quantity} times", else: nil)}
    >
    </div>
    """
  end
end
