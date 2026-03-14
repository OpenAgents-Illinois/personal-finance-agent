# Personal Finance Agent

A Rails web app that connects to your bank accounts, automatically analyzes your spending, and generates actionable recommendations — all running in the background without you having to interact with a chatbot.

---

## How It Works

1. **Connect your bank** — Link a financial institution via Plaid Link (OAuth-like flow in the browser)
2. **Sync transactions** — The backend exchanges tokens and pulls your transactions/balances into a local PostgreSQL database
3. **Analyze** — Background jobs run deterministic Ruby analytics on your spending data
4. **Recommend** — Claude API converts those analytics into human-readable recommendations and reports
5. **Display** — Rails views show you the results on a dashboard

---

## Core Capabilities

| Feature | What it does |
|---|---|
| **Spending breakdown** | Aggregates spend by category and merchant, month-over-month |
| **Subscription detection** | Identifies recurring charges (Netflix, SaaS, memberships) and estimates monthly cost |
| **Anomaly detection** | Flags unusual weeks, sudden category spikes, or one-off large transactions |
| **Recommendations** | Generates prioritized action items with estimated monthly savings |
| **Weekly/monthly reports** | Auto-generated financial summaries via Claude API |
| **Progress tracking** | Compares current behavior against prior recommendations |

---

## Tech Stack

- **Rails monolith** — backend, views, business logic
- **Plaid API** — bank data (read-only)
- **Sidekiq + Redis** — background job processing (nightly syncs, analysis, report generation)
- **Claude API** — converts structured analytics into plain-English recommendations
- **Tailwind + Hotwire** — server-rendered UI with progressive enhancement
- **PostgreSQL** — primary database

---

## Key Design Decisions

- **Analytics in Ruby, not Claude** — category aggregation, subscription detection, and anomaly detection are all deterministic Ruby code. Claude only writes summaries.
- **Encrypted tokens** — Plaid access tokens are encrypted at rest and never logged.
- **Autonomous** — once connected, the system runs nightly syncs and generates reports automatically without user interaction.

---

## Setup

### Requirements

- Ruby 3.x
- PostgreSQL
- Redis
- Plaid API credentials
- Anthropic API key

### Environment Variables

```
PLAID_CLIENT_ID=
PLAID_SECRET=
PLAID_ENV=sandbox
ANTHROPIC_API_KEY=
RAILS_MASTER_KEY=
```

### Running Locally

```bash
bundle install
rails db:create db:migrate
bin/dev   # starts Rails + Sidekiq via Procfile.dev
```
