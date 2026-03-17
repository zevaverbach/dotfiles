---
task: Implement media storage for Telegram photos
slug: 20260317-100000_media-storage-telegram-photos
effort: standard
phase: execute
progress: 8/8
mode: interactive
started: 2026-03-17T10:00:00Z
updated: 2026-03-17T10:00:30Z
---

## Context

Telegram `file_id`s are ephemeral — photos received via webhook expire. Before building inbound processing (3.3) or photo analyzer (4.3), Noko needs a storage layer that downloads and persists media locally. This is item #26 in TODO.md.

Scope: protocol + local implementation only. No cloud backends, no Media DB model (that's 26b), no Alembic migration.

### Risks
- Static file mount ordering in FastAPI (must not shadow API routes)
- Media directory creation on startup vs lazy
- Config field naming collisions

## Criteria

- [x] ISC-1: `MediaStorage` protocol defined in `src/media.py` with save and url methods
- [x] ISC-2: `LocalMediaStorage` class implements `MediaStorage` protocol
- [x] ISC-3: `LocalMediaStorage.save()` writes bytes to `media/` directory with unique filename
- [x] ISC-4: `LocalMediaStorage.url()` returns serving path for a stored file
- [x] ISC-5: Config fields `media_storage_dir` and `media_base_url` added to Settings
- [x] ISC-6: FastAPI mounts `media/` directory as static files
- [x] ISC-7: Test verifies save writes file to disk and url resolves
- [x] ISC-8: Test verifies static file serving returns saved content via HTTP

## Decisions

## Verification
