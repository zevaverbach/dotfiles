---
task: Replace Obsidian data with DB; Claude Code on Beelink
slug: 20260504-130000_obsidian-to-db-and-claude-on-beelink
effort: advanced
phase: complete
progress: 35/35
mode: interactive
started: 2026-05-04T09:19:17+02:00
updated: 2026-05-04T09:25:00+02:00
---

## Context

Two parallel workstreams on the Beelink home server (`averbachs@100.113.119.55`, Ubuntu 24.04):

**Task 1 — Replace Obsidian-as-data-store with a database.**
Today, `obsidian-torrent.py` (cron, every minute) `git pull`s `~/repos/obsidian-vault`, parses `TORRENT.md` `## Queue` lines, appends to `/srv/media-ext/queue.txt`, deletes entries, commits + pushes back. Zev finds the Obsidian/git path unreliable. New design: SQLite at `/srv/media-ext/db/beelink.db`, table `torrent_requests`, with a TOTP-gated POST endpoint on the existing dashboard (`beelink.averba.ch`) so any device can add a request. `fetch-torrents.py` and `torrent-status.py` switch their backing store from `queue.txt` / `queue.txt.retries` to the DB. Documentation pages on the dashboard (CRON_DESCRIPTIONS, `/get-started`, supplement-reminder copy) drop all Obsidian/`.md` mentions.

**Task 2 — Move Claude Code workloads from Pi to Beelink.**
Zev's Claude Max subscription is no longer usable on the Pi. Beelink already has `claude` 2.1.81 at `/usr/bin/claude` and 2.1.114 at `~/.local/share/claude/versions/`. Need to (a) confirm/upgrade Beelink claude, (b) log Beelink in via Max, (c) port whichever Pi cron/scripts/triggers were calling claude over to the Beelink, (d) disable on Pi.

### Risks
- **Data loss during torrent migration:** `queue.txt` is currently empty (verified 0 lines), so cutover risk is minimal — but failed retries in `queue.txt.retries` need handling.
- **TOTP bypass on new POST endpoint:** must reuse `totp_auth.check_auth` exactly — no shortcut.
- **qBittorrent password leak:** plaintext exists in `fetch-torrents.py`. Don't propagate it; only edit the queue-read section.
- **Pi specifics unknown:** I don't have visibility into what crons/scripts on the Pi use Claude. Need user input before Task 2 ISC-24+ are executable.
- **Mac-side Obsidian sync break:** removing the cron on Beelink leaves `TORRENT.md` orphaned on Mac. The file should be archived or kept as a reminder only.

### Plan (high level)
1. Build DB layer (schema + helper module).
2. Add `/torrents` GET (form + list) and `/add-torrent` POST (TOTP-gated) to dashboard.
3. Cut `fetch-torrents.py` over to read DB.
4. Cut `torrent-status.py` retry tracking over to DB.
5. Remove `obsidian-torrent.py` from cron, archive script, scrub all Obsidian mentions in dashboard text.
6. Pause for Task 2: ask Zev what's running Claude on the Pi → port → disable Pi.

## Criteria

### Workstream A — Database foundation
- [x] ISC-1: SQLite DB file exists at `/srv/media-ext/db/beelink.db` owned by averbachs
- [x] ISC-2: Schema file `/srv/media-ext/db/schema.sql` (placed at /srv/media-ext/schema.sql alongside db.py — repo not in sync with runtime, runtime is SoT)
- [x] ISC-3: `torrent_requests` table has columns id, raw_text, media_type, status, created_at, processed_at, retry_count, error_msg, source
- [x] ISC-4: DB file mode 0640, parent dir 0750
- [x] ISC-5: Idempotent init via `db.py:_ensure_initialized()`
- [x] ISC-6: `db.py` provides connect, add_torrent_lines, claim_pending, mark_done, mark_failed, mark_retry, list_recent, list_pending

### Workstream B — Replace Obsidian flow
- [x] ISC-7: `/torrents` GET returns HTML form with textarea
- [x] ISC-8: `/add-torrent` POST handler exists
- [x] ISC-9: `/torrents` + `/add-torrent` behind Cloudflare Access (verified: external curl 302 → cloudflareaccess.com login)
- [x] ISC-10: POST inserts each non-empty line into `torrent_requests` with status='pending'
- [x] ISC-11: `/torrents` lists last 20 with status badges
- [x] ISC-12: `fetch-torrents.py` reads from DB (verified by manual run on test row)
- [x] ISC-13: `fetch-torrents.py` updates row status processing/done/failed
- [x] ISC-14: retry tracking now in DB column (queue.txt.retries no longer touched by code)
- [x] ISC-15: `obsidian-torrent.py` cron line removed
- [x] ISC-16: archived to `~/.archive/obsidian-torrent.py.20260504`

### Workstream C — Documentation scrub
- [x] ISC-17: `CRON_DESCRIPTIONS["obsidian-torrent.py"]` removed
- [x] ISC-18: `supplement-reminder.py` Obsidian mention removed
- [x] ISC-19: `render_get_started()` had no Obsidian refs (already clean)
- [x] ISC-20: `render_home()` includes "⬇️ Torrents" nav card
- [x] ISC-21: `grep [Oo]bsidian /srv/media-ext/*.py` → 0 hits
- [x] ISC-22: TORRENT.md removed from Mac vault
- [x] ISC-23: vault git push succeeded (4b81796..30d6af4)
- [x] ISC-24: Beelink vault clone pulled fast-forward, TORRENT.md gone

### Workstream D — Claude Code on Beelink
- N/A: Verified during OBSERVE — Beelink already on Claude Max (`subscriptionType: max`, `rateLimitTier: default_claude_max_5x`), all Beelink scripts already invoke `claude` CLI directly. No migration needed. Task closed by user 2026-05-04.

### Workstream E — Adult-content safeguard (added mid-execute on user report)
- [x] ISC-25: `safety.py` module with `is_adult_result()` (TPB cat 500–599 + keyword fallback) and `is_adult_query()`
- [x] ISC-26: `fetch-torrents.py` `search_torrent` rejects adult-category results before returning them
- [x] ISC-27: `fetch-torrents.py` `generate_alt_queries` Claude prompt explicitly forbids adult content
- [x] ISC-28: `email-torrent.py` `parse_with_claude` prompt explicitly forbids adult content
- [x] ISC-29: `db.add_torrent_lines` rejects lines where `is_adult_query()` matches; dashboard POST surfaces count

### Workstream F — Enable Jellyfin item deletion (added mid-execute on user request)
- [x] ISC-30: `jellyfin` user added to `averbachs` group
- [x] ISC-31: `/mnt/media/{movies,downloads}` are group-writable + setgid (new subdirs inherit group)
- [x] ISC-32: Default POSIX ACL set so future qBittorrent-written files are group-writable
- [x] ISC-33: `jellyfin` service restarted; `sudo -u jellyfin test -w` returns writable for both dirs

### Anti-criteria
- [x] ISC-A-1: No queued torrent request lost (queue.txt was 0 lines pre-migration)
- [x] ISC-A-2: CF Access enforced — anonymous external curl returns 302
- [x] ISC-A-3: qBittorrent password not in db.py / safety.py / schema.sql
- [x] ISC-A-4: error_msg surfaced in /torrents page rows
- [x] ISC-A-5: email-claude.py untouched; email-torrent.py only had the parse-prompt safety guardrail added (functional flow unchanged)
- [x] ISC-A-6: CryptPad untouched, MediaCat untouched, qBittorrent untouched

## Decisions

- 2026-05-04: SQLite over Postgres/MySQL. Beelink already has sqlite3 3.45; remote write via existing dashboard HTTP endpoint = lightweight, no extra service, no extra port.
- 2026-05-04: One DB file (`beelink.db`), one table per cron data store. `torrent_requests` first; `email_threads` and `family_preferences` are out of scope unless Zev asks (currently JSON files, working fine).
- 2026-05-04: Reuse existing TOTP auth module — no new auth surface area.

## Verification

(populated during VERIFY phase)
