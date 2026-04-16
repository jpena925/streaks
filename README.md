# Streaks

A habit tracker with a GitHub-style contribution grid. 

<img width="383" height="558" alt="Screenshot 2026-04-16 at 9 01 55 AM" src="https://github.com/user-attachments/assets/5d653bf2-cd74-4536-9207-4ab34ce765db" />
<img width="386" height="561" alt="Screenshot 2026-04-16 at 9 01 40 AM" src="https://github.com/user-attachments/assets/393e7fea-ad5e-4488-aeb7-a1ce499a16a4" />


## How to Track your habits

1. Add a Habit
2. Name it
3. Decide if it is a simple "did it" or not kind of habit, or it is quantitative in some way (like glasses of water a day).

## Running it locally

You'll need Elixir 1.15+, PostgreSQL, and Node.js installed.

```bash
git clone <this-repo>
cd streaks
mix setup
mix phx.server
```

After running `mix setup` which runs the seeds, login with:
user: demo@streaks.com
password: password123456

check out `localhost:4000` in your browser for your local version

## Stack

- Phoenix 1.8 + LiveView
- PostgreSQL
- Tailwind CSS
- Deployed via Gigalixir (yay free)

## Contributions

Personally, I use this every day and add features as I want them. If you have suggestions, please open an issue and I'd be happy to take a look.

