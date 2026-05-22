---
task: Clean OpenClaw, remove movie night, add TOTP + get-started
slug: 20260414-beelink-cleanup-and-get-started
effort: advanced
phase: complete
progress: 34/34
mode: interactive
started: 2026-04-14T12:00:00-04:00
updated: 2026-04-14T12:05:00-04:00
---

## Context

Four changes to the Beelink home server (Ubuntu 24.04, SSH via `averbachs@100.113.119.55`):

1. **Clean up OpenClaw** — `openclaw-gateway` process (PID 301177, 398MB RAM). Config in `~/.openclaw/`, binaries in `~/.npm-global/bin/openclaw` and `~/.local/bin/openclaw-*`.

2. **Remove movie night** — Two scripts, two crons, dashboard references.

3. **Add per-user TOTP to all email services** — Currently only `email-claude.py` has TOTP (single shared secret). `email-torrent.py` and `mcat-email.py` have whitelist only. New design: per-user TOTP secrets stored in `/srv/media-ext/totp-secrets/` as `{email}.secret`. All three scripts verify TOKEN in email body against the sender's individual secret.

4. **Add `/get-started` endpoint** — Guide for family (Android/iOS/iPadOS/macOS) on TOTP authenticator setup and email usage.

### Risks
- Per-user TOTP migration: existing emails without tokens will be rejected after deploy
- Family needs to be set up with authenticator apps before TOTP enforcement goes live
- Dashboard restart needed after code changes

### Plan
1. OpenClaw cleanup (kill, rm)
2. Movie night removal (crons, scripts, dashboard)
3. Generate per-user TOTP secrets, create shared verify module
4. Add TOTP to email-torrent.py and mcat-email.py
5. Build get-started page with QR codes or setup instructions
6. Edit dashboard.py for movie night removal + get-started route
7. Restart dashboard once

## Criteria

### Task 1: OpenClaw Cleanup
- [x] ISC-1: openclaw-gateway process is stopped
- [x] ISC-2: ~/.openclaw directory removed from Beelink
- [x] ISC-3: ~/.npm-global/bin/openclaw binary removed
- [x] ISC-4: ~/.local/bin/openclaw-* scripts removed
- [x] ISC-5: ~/.cache/claude-cli-nodejs the-dude-kit cache removed
- [x] ISC-6: ~/repos/api-key-proxy/openclaw-secret file removed
- [x] ISC-7: No openclaw processes running after cleanup (ps check)

### Task 2: Movie Night Removal
- [x] ISC-8: movie-night-suggest.py cron entry removed from crontab
- [x] ISC-9: movie-night-votes.py cron entry removed from crontab
- [x] ISC-10: movie-night-suggest.py script archived or removed
- [x] ISC-11: movie-night-votes.py script archived or removed
- [x] ISC-12: CRON_DESCRIPTIONS movie-night entries removed from dashboard.py
- [x] ISC-13: /movie-night route removed from DashboardHandler
- [x] ISC-14: render_movie_night function removed from dashboard.py
- [x] ISC-15: Movie Night nav card removed from render_home
- [x] ISC-16: get_movie_night_state function removed from dashboard.py
- [x] ISC-17: FAMILY_MEMBER_NAMES constant removed if unused

### Task 3: Per-User TOTP
- [x] ISC-18: totp-secrets directory created at /srv/media-ext/totp-secrets/
- [x] ISC-19: Individual TOTP secret file generated per family member
- [x] ISC-20: Shared totp_auth.py module with verify function
- [x] ISC-21: email-torrent.py imports and enforces TOTP verification
- [x] ISC-22: mcat-email.py imports and enforces TOTP verification
- [x] ISC-23: email-claude.py migrated to use shared totp_auth.py module
- [x] ISC-24: Auth failure replies include helpful error message
- [x] ISC-25: Valid window accounts for email delivery delay (±5 steps)

### Task 4: Get-Started Endpoint
- [x] ISC-26: /get-started route added to DashboardHandler
- [x] ISC-27: Page explains email addresses and what each service does
- [x] ISC-28: Page explains TOTP requirement with TOKEN format
- [x] ISC-29: Android authenticator setup instructions included
- [x] ISC-30: iOS authenticator setup instructions included
- [x] ISC-31: iPadOS setup instructions included
- [x] ISC-32: macOS setup instructions included
- [x] ISC-33: Get-started nav card added to home page
- [x] ISC-34: Page uses SHARED_STYLES for visual consistency

### Anti-criteria
- [x] ISC-A-1: No existing working services broken after changes
- [x] ISC-A-2: No TOTP secrets or API tokens exposed in get-started page

## Decisions

- 2026-04-14: Per-user TOTP secrets (not per-service or shared). One authenticator entry per family member works across all services. Revocation is per-person.
- 2026-04-14: Shared totp_auth.py module to avoid duplicating TOTP logic in 3 scripts.

## Verification

- ISC-1 through ISC-7: `ps aux | grep claw` returns nothing, `ls ~/.openclaw` returns "GONE", no openclaw binaries found
- ISC-8 through ISC-11: `crontab -l` shows no movie-night entries, scripts moved to `~/.archive/`
- ISC-12 through ISC-17: `grep movie.night dashboard.py` returns only a log filename reference (benign), no CRON_DESCRIPTIONS entries, no route, no render function, no nav card
- ISC-18 through ISC-25: 5 per-user secret files in `/srv/media-ext/totp-secrets/`, `totp_auth.py` tested with live token verification, all 3 email scripts compile and import `check_auth`
- ISC-26 through ISC-34: `/get-started` returns 200, contains 3 TOKEN references, 9 platform sections, uses SHARED_STYLES, nav card present on home page
- ISC-A-1: All 8 Python scripts compile clean, dashboard responds 200 on all endpoints
- ISC-A-2: `curl get-started | grep secret` returns nothing — no secrets exposed
