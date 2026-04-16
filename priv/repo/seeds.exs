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
earliest_date = Date.add(today, -20)
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
    tracking_mode: :binary,
    position: 0,
    user_id: user.id,
    inserted_at: habit_created_at,
    updated_at: habit_created_at
  })

drinks_habit =
  Repo.insert!(%Habit{
    name: "Drinks",
    tracking_mode: :quantity,
    position: 1,
    user_id: user.id,
    inserted_at: habit_created_at,
    updated_at: habit_created_at
  })

mood_options = [
  %{id: "red", color: "#ef4444", label: "Red"},
  %{id: "orange", color: "#f97316", label: "Orange"},
  %{id: "yellow", color: "#eab308", label: "Yellow"},
  %{id: "green", color: "#22c55e", label: "Green"}
]

mood_habit =
  Repo.insert!(%Habit{
    name: "Mood",
    tracking_mode: :qualitative,
    qualitative_options: mood_options,
    position: 2,
    user_id: user.id,
    inserted_at: habit_created_at,
    updated_at: habit_created_at
  })

mood_start = earliest_date

mood_data =
  for i <- 0..20 do
    date = Date.add(mood_start, i)

    option_id =
      cond do
        rem(i, 9) == 0 -> "red"
        rem(i, 5) == 0 -> "orange"
        rem(i, 2) == 0 -> "green"
        true -> "yellow"
      end

    {date, option_id}
  end

mood_color_by_id = Map.new(mood_options, fn %{id: id, color: color} -> {id, color} end)

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

for {date, option_id} <- mood_data do
  Repo.insert!(%HabitCompletion{
    habit_id: mood_habit.id,
    completed_on: date,
    qualitative_option_id: option_id,
    qualitative_color: Map.fetch!(mood_color_by_id, option_id)
  })
end

IO.puts("\n✅ Seeds completed!")
IO.puts("Login with: demo@streaks.com / password123456")
