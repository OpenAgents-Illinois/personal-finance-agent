# AGENTS.md

## Project Overview

This repository implements the **Personal Finance Agent** defined in `SPEC.md`.

Codex should follow the product architecture described in `SPEC.md` and implement the application incrementally.

Codex may use the agents and skills defined in the `.Codex` directory to structure implementation.

The application itself should remain a **standard Rails application**. Codex agents are **development roles only**, not runtime components.

---

# Implementation Philosophy

Codex should:

- follow idiomatic Rails conventions
- keep controllers thin
- implement business logic in service objects
- isolate Plaid integration in dedicated services
- isolate Codex API usage in dedicated services
- compute financial analytics deterministically in Ruby
- use background jobs for automation
- prefer clear, modular architecture

The application should remain a **Rails monolith**.

Do not introduce:

- microservices
- unnecessary abstraction layers
- runtime agent frameworks
- complex orchestration libraries

---

# Rails Architecture Rules

Controllers must only:

- handle requests
- call services
- return responses

Business logic must live in: app/services/

Background jobs must live in: app/jobs/

External integrations must live in: app/services/integrations/

Expected service namespaces:

Analysis::
Planning::
Reporting::
Plaid::
Integrations::

---

# Codex Agents

Codex may use the following development agents to structure implementation.

These are **build-time roles**, not application code.

- `rails_foundation`
- `schema_designer`
- `plaid_integrator`
- `analytics_engineer`
- `claude_integration`
- `jobs_orchestrator`
- `ui_builder`
- `testing_agent`

Agent definitions are located in: .Codex/agents/

---

# Codex Skills

Reusable skills are defined in: .Codex/skills/

Examples include:

- `rails_app_bootstrap`
- `rails_service_objects`
- `plaid_transactions_sync`
- `financial_analytics_patterns`
- `claude_json_generation`
- `hotwire_dashboard_ui`

Agents may reference skills when generating code.

---

# Execution Strategy

Codex must implement the project **incrementally**.

Codex must complete the current milestone before implementing the next one.

Milestones:

1. Rails foundation
2. Database schema
3. Plaid integration
4. Financial analytics engine
5. Codex recommendation system
6. Background jobs and automation
7. UI pages
8. Reporting and progress tracking

Codex must **not attempt to implement the entire system at once**.

After completing a milestone, Codex should:

1. summarize files created
2. confirm the app runs
3. wait for the next instruction

---

# Background Job System

The application uses:

- **Sidekiq** for job processing
- **Redis** for job queue storage

Jobs should include:

- transaction synchronization
- financial analysis
- recommendation generation
- weekly report generation
- monthly review generation

Jobs should be designed to be **idempotent where possible**.

---

# Codex AI Usage

Codex is used only for **reasoning and explanation**, not analytics.

Codex may generate:

- financial recommendations
- weekly financial reports
- monthly financial reviews
- progress summaries

Codex must **not** be used to perform deterministic analytics.

Analytics that must be implemented in Ruby:

- category aggregation
- merchant aggregation
- recurring subscription detection
- anomaly detection
- spending comparisons
- savings estimation

Codex should receive **structured analytics summaries** and return structured outputs.

---

# Data Safety Rules

Codex must ensure the application never logs or exposes:

- Plaid access tokens
- bank account identifiers
- sensitive financial payloads

Plaid access tokens must be **encrypted before storage**.

---

# Folder Structure Expectations

The application should follow this structure:

app/
models/
controllers/
views/
jobs/
services/
analysis/
planning/
reporting/
plaid/
integrations/

Codex should avoid introducing unnecessary new top-level directories.

---

# Code Quality Rules

Codex should:

- follow idiomatic Rails patterns
- avoid over-engineering
- use clear naming conventions
- keep files focused and small
- prefer simple service objects
- write tests for services and jobs where practical
- avoid large monolithic classes

---

# Incremental Development Rule

Codex must **never generate the full application in a single step**.

Codex should:

1. complete the current milestone
2. ensure the application runs
3. summarize changes
4. wait for the next instruction