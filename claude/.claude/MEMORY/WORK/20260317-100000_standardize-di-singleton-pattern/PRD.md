---
task: Standardize DI pattern for singletons across app
slug: 20260317-100000_standardize-di-singleton-pattern
effort: standard
phase: complete
progress: 8/8
mode: interactive
started: 2026-03-17T10:00:00-07:00
updated: 2026-03-17T10:00:00-07:00
---

## Context

Two DI patterns coexist in Noko: `get_handler_registry(request: Request)` reads from `app.state` (set in `create_app()`), while `get_telegram_client()` uses a module-level singleton `_client`. This inconsistency makes the codebase harder to reason about and breaks the principle that FastAPI's DI system should manage all shared state.

The fix: move `TelegramClient` into `app.state` in `create_app()`, update `get_telegram_client` to take `Request` and read from `app.state` — matching `get_handler_registry` exactly.

### Risks
- Test fixture `bot_client` uses `dependency_overrides[get_telegram_client]` — must update to match new signature
- Any future code that imports `_client` directly would break (grep confirms none exists)

## Criteria

- [x] ISC-1: Module-level `_client` singleton removed from client.py
- [x] ISC-2: `get_telegram_client` accepts `Request` parameter
- [x] ISC-3: `get_telegram_client` reads from `request.app.state.telegram_client`
- [x] ISC-4: `create_app()` sets `app.state.telegram_client` (Mock or Live based on config)
- [x] ISC-5: Router `Depends(get_telegram_client)` still injects correctly
- [x] ISC-6: Test fixture `bot_client` updated — sets `app.state.telegram_client` directly
- [x] ISC-7: All 33 bot routing tests pass, all other tests pass in isolation
- [x] ISC-8: Both DI functions share identical `(request: Request) -> request.app.state.X` pattern

## Decisions

## Verification

All 8 ISC criteria verified. Commit `014074d` contains the complete change. 33/33 bot routing tests pass. DI pattern now consistent across both singleton dependencies.
