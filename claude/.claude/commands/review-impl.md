---
name: review-impl
description: Review implementation (tests + source) against its plan and project patterns
disable-model-invocation: true
argument-hint: <commit-or-file> [task-description]
---

# Review Implementation

Review the implementation specified by `$ARGUMENTS`.

The first argument is a commit hash, test file, or source file. The optional second
argument describes the task this work addresses. If provided, the review checks the
implementation against that task's requirements.

## Steps

1. **Identify the files** — if given a commit hash, run `git diff <hash>^..<hash>
--stat` to see what changed. If given a file, find the corresponding test/source pair.
Read all relevant files.

2. **Identify the task** — if a task description was given, look for corresponding
plans, specs, or issue descriptions. Otherwise, infer intent from the commit message
or file contents.

3. **Check test coverage:**
   - Does every significant code path have a corresponding test?
   - Flag any untested logic, especially error handling and edge cases.

4. **Check test quality:**
   - Assertions test the right thing (not just status codes — check response bodies, state changes)
   - Proper setup/teardown, no shared mutable state between tests
   - Fixtures used appropriately (not excessive setup in each test)
   - Tests are deterministic (no flaky timing, random data, or order dependence)

5. **Check implementation quality:**
   - Follows the project's existing architectural patterns and layering
   - Error handling is consistent with the rest of the codebase
   - No security issues (unsanitized input, missing auth checks, injection vectors)
   - No deprecated patterns — check what peer files do and match that

6. **Check consistency with existing code:**
   - Does it follow the same patterns as peer modules?
   - Are naming conventions consistent?
   - Is it properly wired in (registered, imported, exported)?

7. **Report** — lead with "looks good" or "issues found." Then:
   - What's done well (briefly)
   - Issues (with file:line references)
   - Suggestions (clearly marked as optional vs. should-fix)

Don't suggest changes to code you haven't read. Don't suggest over-engineering.
