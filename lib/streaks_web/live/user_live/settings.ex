defmodule StreaksWeb.UserLive.Settings do
  use StreaksWeb, :live_view

  on_mount {StreaksWeb.UserAuth, :require_authenticated}

  alias Streaks.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="space-y-8">
        <div>
          <h1 class="text-3xl font-bold text-gray-900 dark:text-white">Settings</h1>
          <p class="mt-2 text-sm text-gray-600 dark:text-gray-400">
            Manage your account preferences and security settings
          </p>
        </div>

        <!-- Appearance Section -->
        <div class="bg-gray-50 dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 p-6 space-y-4">
          <div>
            <h2 class="text-lg font-semibold text-gray-900 dark:text-white flex items-center gap-2">
              <.icon name="hero-paint-brush" class="w-5 h-5" />
              Appearance
            </h2>
            <p class="mt-1 text-sm text-gray-600 dark:text-gray-400">
              Customize how Streaks looks on your device
            </p>
          </div>

          <div class="space-y-3">
            <label class="text-sm font-medium text-gray-700 dark:text-gray-300">
              Theme
            </label>
            <div class="flex gap-3" phx-hook="ThemeSelector" id="theme-selector">
              <button
                phx-click={JS.dispatch("phx:set-theme")}
                data-phx-theme="system"
                class="flex-1 flex flex-col items-center gap-2 p-4 rounded-lg border-2 border-gray-300 dark:border-gray-700 hover:border-gray-400 dark:hover:border-gray-600 transition-colors"
              >
                <.icon name="hero-computer-desktop" class="w-6 h-6 text-gray-700 dark:text-gray-300" />
                <span class="text-sm font-medium text-gray-900 dark:text-white">System</span>
              </button>

              <button
                phx-click={JS.dispatch("phx:set-theme")}
                data-phx-theme="light"
                class="flex-1 flex flex-col items-center gap-2 p-4 rounded-lg border-2 border-gray-300 dark:border-gray-700 hover:border-gray-400 dark:hover:border-gray-600 transition-colors"
              >
                <.icon name="hero-sun" class="w-6 h-6 text-gray-700 dark:text-gray-300" />
                <span class="text-sm font-medium text-gray-900 dark:text-white">Light</span>
              </button>

              <button
                phx-click={JS.dispatch("phx:set-theme")}
                data-phx-theme="dark"
                class="flex-1 flex flex-col items-center gap-2 p-4 rounded-lg border-2 border-gray-300 dark:border-gray-700 hover:border-gray-400 dark:hover:border-gray-600 transition-colors"
              >
                <.icon name="hero-moon" class="w-6 h-6 text-gray-700 dark:text-gray-300" />
                <span class="text-sm font-medium text-gray-900 dark:text-white">Dark</span>
              </button>
            </div>
          </div>
        </div>

        <!-- Account Section -->
        <div class="bg-gray-50 dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 p-6 space-y-4">
          <div>
            <h2 class="text-lg font-semibold text-gray-900 dark:text-white flex items-center gap-2">
              <.icon name="hero-envelope" class="w-5 h-5" />
              Account
            </h2>
            <p class="mt-1 text-sm text-gray-600 dark:text-gray-400">
              Update your email address
            </p>
          </div>

          <.form
            for={@email_form}
            id="email_form"
            phx-submit="update_email"
            phx-change="validate_email"
          >
            <.input
              field={@email_form[:email]}
              type="email"
              label="Email"
              autocomplete="username"
              required
            />
            <div class="mt-4">
              <.button variant="primary" phx-disable-with="Changing...">
                Update Email
              </.button>
            </div>
          </.form>
        </div>

        <!-- Security Section -->
        <div class="bg-gray-50 dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 p-6 space-y-4">
          <div>
            <h2 class="text-lg font-semibold text-gray-900 dark:text-white flex items-center gap-2">
              <.icon name="hero-lock-closed" class="w-5 h-5" />
              Security
            </h2>
            <p class="mt-1 text-sm text-gray-600 dark:text-gray-400">
              Change your password to keep your account secure
            </p>
          </div>

          <.form
            for={@password_form}
            id="password_form"
            action={~p"/users/update-password"}
            method="post"
            phx-change="validate_password"
            phx-submit="update_password"
            phx-trigger-action={@trigger_submit}
          >
            <input
              name={@password_form[:email].name}
              type="hidden"
              id="hidden_user_email"
              autocomplete="username"
              value={@current_email}
            />
            <.input
              field={@password_form[:password]}
              type="password"
              label="New password"
              autocomplete="new-password"
              required
            />
            <.input
              field={@password_form[:password_confirmation]}
              type="password"
              label="Confirm new password"
              autocomplete="new-password"
            />
            <div class="mt-4">
              <.button variant="primary" phx-disable-with="Saving...">
                Update Password
              </.button>
            </div>
          </.form>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_scope.user, token) do
        {:ok, _user} ->
          put_flash(socket, :info, "Email changed successfully.")

        {:error, _} ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    email_changeset = Accounts.change_user_email(user, %{}, validate_unique: false)
    password_changeset = Accounts.change_user_password(user, %{}, hash_password: false)

    socket =
      socket
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:trigger_submit, false)

    {:ok, socket}
  end

  @impl true
  def handle_event("validate_email", params, socket) do
    %{"user" => user_params} = params

    email_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_email(user_params, validate_unique: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form)}
  end

  def handle_event("update_email", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_scope.user
    true = Accounts.sudo_mode?(user)

    case Accounts.change_user_email(user, user_params) do
      %{valid?: true} = changeset ->
        Accounts.deliver_user_update_email_instructions(
          Ecto.Changeset.apply_action!(changeset, :insert),
          user.email,
          &url(~p"/users/settings/confirm-email/#{&1}")
        )

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, socket |> put_flash(:info, info)}

      changeset ->
        {:noreply, assign(socket, :email_form, to_form(changeset, action: :insert))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"user" => user_params} = params

    password_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_password(user_params, hash_password: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form)}
  end

  def handle_event("update_password", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_scope.user
    true = Accounts.sudo_mode?(user)

    case Accounts.change_user_password(user, user_params) do
      %{valid?: true} = changeset ->
        {:noreply, assign(socket, trigger_submit: true, password_form: to_form(changeset))}

      changeset ->
        {:noreply, assign(socket, password_form: to_form(changeset, action: :insert))}
    end
  end
end
