# Streaks

A habit tracker with a GitHub-style contribution grid. Built with Phoenix LiveView.

## What it does

Track daily habits and see your streaks. Click a day to mark it complete, watch your streak counter go up. That's pretty much it.

You can also track quantity-based habits (like "drink 8 glasses of water") which show up as different shades of green based on how many times you did the thing.

## Running it locally

You'll need Elixir 1.15+, PostgreSQL, and Node.js installed.

```bash
git clone <this-repo>
cd streaks
mix setup
mix phx.server
```

Visit `localhost:4000` and you're good to go.

## Tech stack

- Phoenix 1.8 + LiveView
- PostgreSQL
- Tailwind CSS
- Deployed with Docker (Fly.io ready)

## How it works

The whole UI is Phoenix LiveView. The habit grid updates in real-time when you click days.

Timezone detection happens client-side and gets passed to the server, so "today" means today in your timezone, not UTC.

Streaks are calculated on every page load from your completion data:

- Current streak counts backward from today/yesterday
- Longest streak finds the longest consecutive run ever

## Contributions

Work on a feature branch and open a PR. I actually use this all the time so am open to ideas how to make it better, even if its just a refactor.

