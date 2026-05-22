---
task: Add TUI-like interactive features to MediaCat web UI
slug: 20260414-101500_mediacat-web-interactive-features
effort: advanced
phase: complete
progress: 28/28
mode: interactive
started: 2026-04-14T10:15:00+02:00
updated: 2026-04-14T10:50:00+02:00
---

## Context

MediaCat web UI at mcat.averba.ch needed TUI-like keyboard interactivity: vim-style navigation, multi-select, archive, bulk tagging, and URL indexing. All implemented in a single file `/srv/media-ext/mcat-web.py` using vanilla JS and new JSON API endpoints backed by `mediacat` CLI commands.

## Criteria

- [x] ISC-1: j key moves focus highlight down one row
- [x] ISC-2: k key moves focus highlight up one row
- [x] ISC-3: Focused row has visible highlight distinct from hover
- [x] ISC-4: Focus wraps or clamps at table boundaries
- [x] ISC-5: Enter on focused row navigates to item detail page
- [x] ISC-6: / key focuses the search input field
- [x] ISC-7: Spacebar toggles selection on focused row
- [x] ISC-8: x key toggles selection on focused row
- [x] ISC-9: Selected rows have distinct visual style from focused
- [x] ISC-10: Shift+j selects current row and moves focus down
- [x] ISC-11: Shift+k selects current row and moves focus up
- [x] ISC-12: Selection count shown in stats bar when >0
- [x] ISC-13: y key archives all selected rows via API
- [x] ISC-14: y with no selection archives the focused row
- [x] ISC-15: Archived rows removed from table with animation
- [x] ISC-16: Undo toast appears after archive with clickable undo
- [x] ISC-17: Undo restores archived items and re-inserts rows
- [x] ISC-18: Archive API endpoint calls mediacat archive
- [x] ISC-19: t key opens tag editor for focused row
- [x] ISC-20: t with selection opens bulk tag editor for all selected
- [x] ISC-21: Tag editor allows adding comma-separated tags
- [x] ISC-22: Tag changes applied via API calling mediacat tags apply
- [x] ISC-23: Undo toast appears after tag change
- [x] ISC-24: Undo restores previous tags
- [x] ISC-25: UI element to input a URL for indexing
- [x] ISC-26: Submit triggers mediacat sum via API
- [x] ISC-27: Progress/status feedback while indexing runs
- [x] ISC-28: New item appears in catalog after indexing completes
- [x] ISC-A1: Keyboard shortcuts must not fire when input/textarea focused
- [x] ISC-A2: Existing pagination, tag filter, live search not broken

## Decisions

- Index URL moved from inline input bar to modal (per user feedback) — cleaner topbar
- All API endpoints use JSON, legacy form POST preserved for item detail page tag editor
- Index jobs run in background threads with polling — mediacat sum can take minutes
- Tag undo stores previous tags client-side, restores via `--mode set`
- `i` keyboard shortcut added for index modal (not in original request, natural addition)

## Verification

All 28+2 criteria verified via browser testing through SSH tunnel (Playwright) and API curl tests. Screenshots captured for navigation, selection, shift-extend, tag modal, index modal, and escape-clear.
