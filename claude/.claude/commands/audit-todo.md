---
name: audit-todo
description: Cross-reference TODO/task tracking files against the actual codebase to find gaps, stale items, or unchecked completed work
disable-model-invocation: true
argument-hint: [todo-file]
---

# Audit TODO

Cross-reference task tracking files against the codebase.

If `$ARGUMENTS` specifies a file, use that. Otherwise, look for common task tracking
files: `TODO.md`, `plans/TODO.md`, `PROJECT.md`, or similar.

## Steps

1. **Find and read task tracking files** — TODO lists, project plans, outlines, or
roadmaps in the repo.

2. **Check for stale completed items** — for each checked-off item, verify the code
actually exists:
   - Do the claimed files/modules exist?
   - Spot-check a few: does the code match what the TODO claims was built?

3. **Check for unchecked completed work** — for each open item, check if it's actually
been implemented:
   - Search for files/functions that match the description
   - Check `git log --oneline -30` for commits that may have done the work
   - If found, flag it: "This appears done but isn't checked off"

4. **Check spec/outline coverage** — if there's a spec, outline, or roadmap, verify
every item is either:
   - Checked off in the TODO, OR
   - Listed as an open item, OR
   - Explicitly deferred with rationale
   - Flag any spec items missing from the TODO entirely

5. **Check dependency accuracy** — for items with dependency annotations, verify the
dependencies are actually satisfied or not. Flag items marked as blocked where the
blocker is already done.

6. **Report:**
   - Items that are done but not checked off
   - Items missing from the TODO that should be there
   - Stale items (checked off but code doesn't exist)
   - Dependency annotations that are outdated
