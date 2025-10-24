# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Streaks.Repo.insert!(%Streaks.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Streaks.Repo
alias Streaks.Accounts.User
alias Streaks.Habits.{Habit, HabitCompletion}

# clear data if running seeds multiple times
Repo.delete_all(HabitCompletion)
Repo.delete_all(Habit)
Repo.delete_all(User)

{:ok, user} =
  %User{}
  |> User.email_changeset(%{email: "demo@streaks.com"})
  |> Ecto.Changeset.change()
  |> User.password_changeset(%{password: "password123456"})
  |> User.confirm_changeset()
  |> Repo.insert()

today = Date.utc_today()
earliest_date = Date.add(today, -13)
habit_created_at = DateTime.new!(earliest_date, ~T[00:00:00], "Etc/UTC")

workout_dates = [
  Date.add(today, -13),
  Date.add(today, -12),
  Date.add(today, -10),
  Date.add(today, -8),
  Date.add(today, -7),
  Date.add(today, -5),
  Date.add(today, -3),
  Date.add(today, -2),
  Date.add(today, -1)
]

drinks_data = [
  {Date.add(today, -13), 2},
  {Date.add(today, -12), 3},
  {Date.add(today, -11), 1},
  {Date.add(today, -9), 2},
  {Date.add(today, -8), 9},
  {Date.add(today, -6), 7},
  {Date.add(today, -5), 1},
  {Date.add(today, -4), 57},
  {Date.add(today, -2), 2},
  {Date.add(today, -1), 5}
]

# create habits with backdated created_at
workout_habit =
  Repo.insert!(%Habit{
    name: "Workout",
    has_quantity: false,
    user_id: user.id,
    inserted_at: habit_created_at,
    updated_at: habit_created_at
  })

drinks_habit =
  Repo.insert!(%Habit{
    name: "Drinks",
    has_quantity: true,
    user_id: user.id,
    inserted_at: habit_created_at,
    updated_at: habit_created_at
  })

# mark habits as completed
for date <- workout_dates do
  Repo.insert!(%HabitCompletion{
    habit_id: workout_habit.id,
    completed_on: date
  })
end

for {date, quantity} <- drinks_data do
  Repo.insert!(%HabitCompletion{
    habit_id: drinks_habit.id,
    completed_on: date,
    quantity: quantity
  })
end

IO.puts("\n✅ Seeds completed!")
IO.puts("Login with: demo@streaks.com / password123456")
