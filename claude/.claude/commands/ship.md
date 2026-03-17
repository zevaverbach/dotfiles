# Ship: Self-Review, Implementation Review, then Commit

Review all uncommitted changes, check implementation quality, iterate until clean, then commit.

## Steps

1. Run `git diff` (staged + unstaged) to see all changes since the last commit.

2. **Self-review**: Identify 1–3 concrete issues you'd flag in a PR review. Consider:
   - Unnecessary complexity or dead code
   - Naming that could be clearer
   - Missing edge cases or error handling at system boundaries
   - Duplication that should be consolidated
   - Anything that would make a reviewer say "nit" or "why?"

3. Fix any issues worth fixing. If none are, say so briefly and move on.

4. **Implementation review** — read all changed files (not just the diff) and check:
   - **Test coverage:** Does every significant code path have a test? Flag untested error handling and edge cases.
   - **Test quality:** Assertions check the right thing (not just status codes). No shared mutable state. Deterministic.
   - **Implementation quality:** Follows project architectural patterns. Error handling consistent with peer code. No security issues. No deprecated patterns.
   - **Consistency:** Naming conventions match peer modules. Properly wired in (registered, imported, exported).

5. If issues are found, fix them and re-run step 4. Loop until clean (max 3 iterations).

6. If still not clean after 3 iterations, stop and tell the user what remains unresolved. Do NOT commit.

7. If clean, proceed with `/commit`.
