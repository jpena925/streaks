defmodule StreaksWeb.StreakLive.FormComponent do
  use StreaksWeb, :live_component

  alias Streaks.Habits

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage streak records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="streak-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:year]} type="number" label="Year" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Streak</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{streak: streak} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Habits.change_streak(streak))
     end)}
  end

  @impl true
  def handle_event("validate", %{"streak" => streak_params}, socket) do
    changeset = Habits.change_streak(socket.assigns.streak, streak_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"streak" => streak_params}, socket) do
    save_streak(socket, socket.assigns.action, streak_params)
  end

  defp save_streak(socket, :edit, streak_params) do
    case Habits.update_streak(socket.assigns.streak, streak_params) do
      {:ok, streak} ->
        notify_parent({:saved, streak})

        {:noreply,
         socket
         |> put_flash(:info, "Streak updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_streak(socket, :new, streak_params) do
    case Habits.create_streak(streak_params) do
      {:ok, streak} ->
        notify_parent({:saved, streak})

        {:noreply,
         socket
         |> put_flash(:info, "Streak created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
