---
task: Add rule-level sieve tools with read-modify-write
slug: 20260322-170500_sieve-rule-level-tools
effort: extended
phase: complete
progress: 20/20
mode: interactive
started: 2026-03-22T17:05:00-04:00
updated: 2026-03-22T17:06:00-04:00
---

## Context

The script-level sieve tools (list/get/put/delete/check/activate) are built. Now we need a rule-level abstraction so Claude (or Zev) can say "filter Chase emails to Notifications" without knowing sieve syntax.

The approach: mark rules we manage with comment delimiters (`# [MCP-RULE:id]` / `# [/MCP-RULE:id]`), so we can find, list, and remove them without parsing the full sieve language. Existing rules (from Fastmail's web UI or manually written) are preserved untouched.

Three new tools:
- `sieve_add_rule` — structured inputs → generates sieve rule → inserts into active script
- `sieve_list_rules` — parses managed rules from active script, returns structured list
- `sieve_remove_rule` — removes a managed rule by ID from the active script

**Not requested:** full sieve parser, modifying existing non-managed rules, vacation/redirect support (keep scope tight).

### Risks
- Fastmail's web UI may not understand our comment markers and could strip them on next save
- The `require` statement at the top of the script needs careful merging (can't have duplicates)
- If no active script exists, we need to create one from scratch
- Rule IDs must be stable and unique across add/remove cycles

## Criteria

- [x] ISC-1: sieve_add_rule accepts `from` field for sender matching
- [x] ISC-2: sieve_add_rule accepts `subject_contains` field for subject matching
- [x] ISC-3: sieve_add_rule accepts `to` field for recipient matching
- [x] ISC-4: sieve_add_rule accepts `action` field (fileinto, discard, keep, redirect)
- [x] ISC-5: sieve_add_rule accepts `folder` field for fileinto destination
- [x] ISC-6: sieve_add_rule accepts `skip_inbox` boolean flag
- [x] ISC-7: sieve_add_rule generates valid sieve syntax with comment markers
- [x] ISC-8: sieve_add_rule reads existing active script before modifying
- [x] ISC-9: sieve_add_rule merges `require` extensions without duplicates
- [x] ISC-10: sieve_add_rule validates script via checkScript before saving
- [x] ISC-11: sieve_add_rule creates new script if none exists
- [x] ISC-12: sieve_add_rule assigns unique rule IDs
- [x] ISC-13: sieve_list_rules returns structured rule objects from active script
- [x] ISC-14: sieve_list_rules includes rule ID, conditions, and action for each rule
- [x] ISC-15: sieve_list_rules returns empty array when no managed rules exist
- [x] ISC-16: sieve_remove_rule deletes a rule by ID from the active script
- [x] ISC-17: sieve_remove_rule preserves all other rules and non-managed content
- [x] ISC-18: sieve_remove_rule cleans up unused require extensions
- [x] ISC-19: All three tools registered in index.ts with Zod schemas
- [x] ISC-20: Project builds successfully with npm run build
- [x] ISC-A-1: Anti: existing script-level tools unchanged
- [x] ISC-A-2: Anti: non-managed sieve rules preserved during add/remove

## Decisions

- 2026-03-22 17:05: Using comment-delimited markers over full sieve parsing — simpler, sufficient for our rules, avoids parser rabbit hole
- 2026-03-22 17:05: REVISED: Inject rules into existing active script, not a separate script. Fastmail only runs one active script — a separate one would disable UI rules. Comment markers let us find our rules within any script.
- 2026-03-22 17:06: Default script name "mcp-sieve" used only when NO active script exists yet
