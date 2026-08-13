---
task: Verify Beelink Matt Zoller Seitz review scanner health
slug: 20260704-182037_check-mzs-scanner-status
effort: standard
phase: learn
progress: 9/9
mode: interactive
started: 2026-07-04T18:20:37Z
updated: 2026-07-04T18:20:37Z
---

## Context

Zev asked whether "the beelink's Matt Soller Zeitz scanner" is working as expected. This
phrase doesn't match any documented service verbatim, so the first job was identifying what
he meant, then actually verifying it.

Resolved: `/srv/media-ext/scan-mzs.py` on the Beelink home server (100.113.119.55) — "mzs" =
Matt Zoller Seitz, the Roger Ebert site film critic. It's a monthly cron (`0 8 1 * *`) that
reads MZS's RSS feed, opens each review in headless Chromium to get past Cloudflare, pulls the
star rating out of the page's JSON-LD, and queues anything rated >=4.0 stars as a torrent
request (movie or TV). Not previously captured in `reference_beelink.md` — worth adding there.

### Risks
- Silent failure mode: script could run "successfully" (exit 0, log entries) while a broken
  rating-parse or CF-bypass path caused everything to be undercounted — needs log content
  inspection, not just "did it run."
- Zero-queued outcome (true for all 3 runs) is ambiguous: could mean thresholding is working
  correctly, or extraction is broken and never reaching 4.0. Needed the actual rating values
  to disambiguate.

## Criteria
- [x] ISC-1: Identify what "Matt Soller Zeitz scanner" refers to on Beelink
- [x] ISC-2: Confirm the script exists at a known path on the server
- [x] ISC-3: Confirm cron schedule is registered and matches script's documented cadence
- [x] ISC-4: Confirm most recent run completed without unhandled exceptions
- [x] ISC-5: Confirm RSS feed fetch returned items (not empty/error) on the last 3 runs
- [x] ISC-6: Confirm Cloudflare bypass via headless Chromium succeeded (ratings extracted, not None)
- [x] ISC-7: Confirm dedup table (seen_reviews) row count matches processed-item count across runs
- [x] ISC-8: Confirm zero-queued outcome is explained by ratings below threshold, not extraction failure
- [x] ISC-9: Identify any non-blocking anomalies worth flagging (media_type gaps, log timezone)

## Decisions
- Treated "working as expected" as: runs on schedule, extracts real data, dedups correctly,
  and its "0 queued" result is explained by actual rating values rather than silent breakage.
- Did not restart/re-run the script live (would double-hit MZS's site and risk CF rate limiting)
  — verification was done entirely from existing logs + sqlite state, which was sufficient.

## Verification
- `crontab -l` on Beelink shows `0 8 1 * * /usr/bin/python3 /srv/media-ext/scan-mzs.py` registered.
- `scan-mzs.log` shows 3 clean runs (2026-05-04, 2026-06-01, 2026-07-01), each ending in
  `Done: N new request(s) queued` with no tracebacks or ERROR lines.
- Each run's "Feed has N review item(s)" / "M new (not previously seen)" line is followed by one
  rating extraction line per new item — all 11 items across 3 runs got a numeric rating, meaning
  the headless-Chromium Cloudflare bypass and JSON-LD parse are both succeeding, not silently failing.
- `sqlite3 /srv/media-ext/db/beelink.db "SELECT * FROM seen_reviews"` returns exactly 11 rows
  matching the 11 processed titles in the log, confirming the idempotent dedup table is in sync.
- Ratings observed: 1.0, 3.5, 3.0, 3.5, 1.0, 2.5, 3.0, 1.5, 2.5, 2.5, 3.0 — max is 3.5, so
  `was_added=1` correctly never fired (all 11 rows show `was_added=0`); the 4.0 threshold is
  the reason nothing queued, not a broken extraction path.
- Anomaly (non-blocking): "Star Wars: The Mandalorian and Grogu" has `media_type=NULL` instead of
  movie/tv — its JSON-LD `itemReviewed.@type` didn't match the movie/tv regex. Harmless here since
  its 1.5 rating wouldn't have queued anyway, but the same gap would matter on a future >=4.0 TV review.
- Anomaly (non-blocking): log line timestamps for June/July show 06:00:0x while the log file's
  mtime (`ls -la`) shows 08:00 — a 2-hour discrepancy between Python's `logging` timestamp and
  filesystem time, suggesting a TZ mismatch between the cron environment and the shell environment
  (harmless, just confusing if debugging by log timestamp).
