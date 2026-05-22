---
task: Dashboard restructure and Claude email bot setup
slug: 20260322-140000_dashboard-restructure-claude-email-bot
effort: extended
phase: complete
progress: 18/18
mode: interactive
started: 2026-03-22T14:00:00-04:00
updated: 2026-03-22T14:00:30-04:00
---

## Context

Zev has 8 cron jobs running on beelink handling torrents, movie night, MediaCat, Obsidian, and a supplement reminder. The current web dashboard at `beelink.averba.ch` has a `/movie-night` route that contains everything — downloads, movie night, crons, logs. He wants:

1. **Dashboard restructure**: Move "Scheduled Tasks" out of `/movie-night` into a new `/dashboard` route that serves as an overview of ALL automation. Un-redact email addresses so the dashboard shows the full picture.
2. **Inventory**: List all crons, keywords, and email addresses in the chat.
3. **Claude email bot**: New cron watching for emails from `zev@averba.ch` to `claude@averba.ch`, running Claude CLI on the body (including slash commands), and replying with results.

### Risks
- Claude CLI on beelink may not have access to the same slash commands as Zev's local machine
- Long-running Claude prompts could time out in a cron context
- Need to ensure only zev@averba.ch can trigger Claude (security)

## Criteria

- [x] ISC-1: `/dashboard` route exists and returns 200 in dashboard.py
- [x] ISC-2: `/dashboard` shows all 9 cron jobs with descriptions
- [x] ISC-3: `/dashboard` shows email addresses for each email-triggered cron
- [x] ISC-4: `/dashboard` shows cron schedules in human-readable form
- [x] ISC-5: `/dashboard` shows keywords/triggers for each automation
- [x] ISC-6: `/movie-night` no longer contains the Scheduled Tasks section
- [x] ISC-7: `/movie-night` retains all other content unchanged
- [x] ISC-8: Home page (`/`) links to `/dashboard` as a nav card
- [x] ISC-9: `email-claude.py` script exists at `/srv/media-ext/`
- [x] ISC-10: `email-claude.py` monitors `claude@averba.ch` via JMAP
- [x] ISC-11: `email-claude.py` only processes emails from `zev@averba.ch`
- [x] ISC-12: `email-claude.py` passes email body to Claude CLI with `-p`
- [x] ISC-13: `email-claude.py` supports slash commands in email body
- [x] ISC-14: `email-claude.py` replies with Claude output via JMAP
- [x] ISC-15: `email-claude.py` uses lock file to prevent concurrent runs
- [x] ISC-16: `email-claude.py` tracks processed email IDs in state file
- [x] ISC-17: Cron entry added for `email-claude.py` running every minute
- [x] ISC-18: Inventory of all crons/emails/keywords provided in chat
- [x] ISC-A-1: Anti: Non-zev senders cannot trigger Claude email bot
