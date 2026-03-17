---
task: Audit and remove unnecessary db.refresh() calls
slug: 20260317-100000_remove-unnecessary-db-refresh
effort: standard
phase: verify
progress: 8/8
mode: interactive
started: 2026-03-17T10:00:00-07:00
updated: 2026-03-17T10:05:00-07:00
---

## Context

With `expire_on_commit=False` in `src/database.py`, SQLAlchemy objects retain their Python-side attribute values after commit. `db.refresh()` after an UPDATE is unnecessary because all values were already set via `setattr()`. After a CREATE, `refresh()` is still needed for `server_default` columns like `created_at` (which use `func.now()` on the DB side).

### Risks
None materialized. All update paths only modify Python-side attributes. No `updated_at` server-side columns exist.

## Criteria

- [x] ISC-1: topics.py update_topic refresh removed (line 103)
- [x] ISC-2: initiatives.py update_initiative refresh removed (line 102)
- [x] ISC-3: workflows.py update_workflow refresh removed (line 102)
- [x] ISC-4: enrollments.py update_enrollment refresh removed (line 102)
- [x] ISC-5: members.py update_me refresh removed (line 56)
- [x] ISC-6: action_items.py update_action_item refresh removed (line 161)
- [x] ISC-7: All post-create refresh calls preserved (10 instances)
- [x] ISC-8: All tests pass after changes

## Decisions

Only removed refresh after UPDATE operations. Kept all 10 post-CREATE refresh calls because `created_at` uses `server_default=func.now()`.

## Verification

- ISC-1–6: Verified via grep — 11 refresh calls remain, all after creates or relationship loads
- ISC-7: Grep confirms 11 remaining calls, all preceded by `db.add()` or loading relationships
- ISC-8: 125 tests pass, 0 failures. Pre-existing errors (RuntimeError: Runner.run()) unrelated to changes.
