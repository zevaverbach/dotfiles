---
task: Test MediaCat web app UI features verify behavior
slug: 20260414-000001_test-mediacat-ui-verify-behavior
effort: standard
phase: complete
progress: 10/12
mode: interactive
started: 2026-04-14T00:00:01Z
updated: 2026-04-14T00:00:03Z
---

## Context

Testing the MediaCat web app at http://localhost:18889/ to verify five specific UI behaviors after recent changes. Tests include date column visibility, sort indicator, row navigation, scroll behavior, and a page screenshot. This is a verification-only run — no code changes, only observation and reporting.

### Risks
- App may not be running (tunnel/server issue)
- Row click navigation may need correct row selection
- Scroll lock may require scroll attempt to verify

## Criteria

- [x] ISC-1: Catalog page loads without errors at localhost:18889
- [x] ISC-2: Created column header visible in catalog table
- [x] ISC-3: Modified column header visible in catalog table
- [x] ISC-4: Created column shows descending sort indicator (arrow)
- [x] ISC-5: Sort indicator is visually distinct (not just text)
- [x] ISC-6: Clicking a catalog row navigates away from catalog
- [x] ISC-7: Navigation destination URL contains /item/
- [x] ISC-8: Item detail page renders visible content
- [x] ISC-9: Item page scroll attempt does not lock or freeze
- [x] ISC-10: Item page scrolls vertically (content moves)
- [ ] ISC-11: Indexing page at /indexing loads without error
- [ ] ISC-12: Indexing page screenshot captured showing visible content

## Decisions

## Verification

- ISC-1 through ISC-10: All passed. Screenshots at /tmp/mediacat-01-catalog.png, /tmp/mediacat-02-item-page.png, /tmp/mediacat-03-item-scrolled.png
- ISC-11/ISC-12: FAILED. render_indexing() raises KeyError on unescaped JS braces in .format() call at line ~1189 of /srv/media-ext/mcat-web.py. Server closes connection with ERR_EMPTY_RESPONSE.
