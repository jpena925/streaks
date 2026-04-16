# Streaks

A habit tracker with a GitHub-style contribution grid.

<img width="734" height="557" alt="Screenshot 2025-11-17 at 6 22 46 PM" src="https://github.com/user-attachments/assets/6b2ffb89-127e-4abd-94a6-d0f125dd6682" />


## Tracking habits (your options)

- **What you’re tracking**
  - **Did it / didn’t**: check it off for the day
  - **Quantitative**: track a number (ex: glasses of water, pages read, minutes meditated)
  - **Qualitative**: track a quality (ex: mood from bad to good, tired from very to not at all etc)

- **How it shows up**
  - **Grid heatmap** so you can spot patterns fast
  - **Streaks** when you’re consistent (and gentle resets when you’re not)

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

Then visit `http://localhost:4000`

## Stack

- Phoenix 1.8 + LiveView
- PostgreSQL
- Tailwind CSS
- Deployed via Gigalixir (yay free)

## Contributions

Personally, I use this every day and add features as I want them. If you have suggestions, please open an issue and I'd be happy to take a look.

