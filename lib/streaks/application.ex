defmodule Streaks.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      StreaksWeb.Telemetry,
      Streaks.Repo,
      {DNSCluster, query: Application.get_env(:streaks, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Streaks.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Streaks.Finch},
      # Start a worker by calling: Streaks.Worker.start_link(arg)
      # {Streaks.Worker, arg},
      # Start to serve requests, typically the last entry
      StreaksWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Streaks.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    StreaksWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
