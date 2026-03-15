---
name: review-commit
description: Review a commit — diff quality, test coverage, and alignment with its stated intent
disable-model-invocation: true
argument-hint: <commit-hash> [task-description]
---

# Review Commit

Review commit `$ARGUMENTS`.

## Steps

1. **Read the diff** — run `git diff <hash>^..<hash>` and `git log -1 --format=%B <hash>` for the message.

2. **Understand intent** — if a task description is provided, use that. Otherwise, infer from the commit message what the commit is trying to accomplish.

3. **Check the diff against intent:**
   - Does it do what the commit message says?
   - Does it do anything *extra* that wasn't asked for? (scope creep)
   - Are there files that should have been changed but weren't?

4. **Check quality in the diff:**
   - New tests: do they test the right things? Missing edge cases?
   - New source: follows project patterns and conventions?
   - Modified tests: did changes break the intent of existing tests?
   - Any deprecated APIs, missing error handling, or inconsistencies with peer code?

5. **Check for issues:**
   - Security: unsanitized input? missing auth? injection vectors?
   - Data integrity: cascade effects handled? constraints respected?
   - Test isolation: shared mutable state? missing cleanup?

6. **Report** — state whether the commit looks good for its stated purpose, then list any issues. Keep it concise — this is a commit review, not a full code audit.
