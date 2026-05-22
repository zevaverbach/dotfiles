---
task: Weave 15 critical audit flaws into Noko roadmap
slug: 20260317-100500_noko-audit-roadmap-integration
effort: extended
phase: complete
progress: 18/18
mode: interactive
started: 2026-03-17T10:05:00-07:00
updated: 2026-03-17T10:06:00-07:00
---

## Context

Zev provided a comprehensive 15-item security audit of the Noko codebase. These findings need to be integrated into the existing PROJECT_MANAGER.md roadmap with proper prioritization, task decomposition, and prompt blocks matching the existing conventions. Cross-referencing with code reveals some findings are already fixed, some are already tracked, and some are new.

### Findings Triage

**Already Fixed (2):** Audit #1 partially (targeted invites check email, but open invites still vulnerable), Audit #5 assessed as fixed by agent but actually still broken (commit after 404 check).

**Already Tracked — needs update (3):** #6 → C9 (add timezone detail), #13 → P1 Redis (already comprehensive), #12 → #38 GDPR (add RESTRICT FK callout).

**Already "Done" but incomplete (1):** #15 Pagination — Item 18 marked DONE but missing tie-breaker columns.

**New findings to add (9):** #1 ATO open invites, #2 Cross-tenant topic DoS, #3 Extended role RBAC bypass, #4 Media path traversal, #5 select_family token replay, #7 Timezone stripping, #8 Detached instances, #9 Silent ping blackhole, #10 Vacation ghost tasks, #11 Refresh endpoint paradox, #14 O(N) ORM deletes.

### Risks

- Misjudging which findings are already fixed could create false confidence
- Existing task numbering (C1-C16, A1-A2, 14-38) must be extended consistently
- Must not break existing cross-references in TODO.md

## Criteria

- [x] ISC-1: New Critical Fixes section contains all P0 security findings
- [x] ISC-2: ATO via open invite finding has subtasks and prompt block
- [x] ISC-3: Cross-tenant topic DoS finding has subtasks and prompt block
- [x] ISC-4: Path traversal in media finding has subtasks and prompt block
- [x] ISC-5: Token replay in select_family has subtasks and prompt block
- [x] ISC-6: Extended role RBAC bypass has subtasks and prompt block
- [x] ISC-7: Refresh endpoint paradox has subtasks and prompt block
- [x] ISC-8: Timezone stripping in scheduler has subtasks and prompt block
- [x] ISC-9: Silent ping blackhole has subtasks and prompt block
- [x] ISC-10: Vacation ghost tasks has subtasks and prompt block
- [x] ISC-11: Detached instances in invites has subtasks and prompt block
- [x] ISC-12: O(N) ORM deletes in workflows has subtasks and prompt block
- [x] ISC-13: Pagination tie-breaker reopened with fix description
- [x] ISC-14: GDPR section updated with RESTRICT FK blocker note
- [x] ISC-15: C9 scheduler section updated with timezone detail from audit
- [x] ISC-16: Critical path updated to reflect new P0 security fixes first
- [x] ISC-17: Each finding has correct severity and "Fix before" trigger
- [x] ISC-18: All new items use consistent numbering extending existing scheme
- [x] ISC-A-1: No existing completed items are modified or removed
