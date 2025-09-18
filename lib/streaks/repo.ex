defmodule Streaks.Repo do
  use Ecto.Repo,
    otp_app: :streaks,
    adapter: Ecto.Adapters.Postgres
end
