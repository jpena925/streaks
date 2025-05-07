# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# This will create a seed user for easy login in development.

alias Streaks.Accounts
import Ecto.Changeset
import Ecto.Query

email = "admin@gmail.com"
password = "password1234"

user = Accounts.get_user_by_email(email)

user =
  if user do
    user
  else
    {:ok, user} = Accounts.register_user(%{
      email: email,
      password: password,
      password_confirmation: password
    })
    user
  end

Streaks.Repo.update!(
  change(user, confirmed_at: DateTime.truncate(DateTime.utc_now(), :second))
)
