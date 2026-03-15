# Ship: Self-Review then Commit

Review all uncommitted changes as if you were a critical PR reviewer. Perform one round of refinement, then commit.

## Steps

1. Run `git diff` (staged + unstaged) to see all changes since the last commit.
2. **Self-review**: Identify 1–3 concrete issues you'd flag in a PR review. Consider:
   - Unnecessary complexity or dead code
   - Naming that could be clearer
   - Missing edge cases or error handling at system boundaries
   - Duplication that should be consolidated
   - Anything that would make a reviewer say "nit" or "why?"
3. Present the issues to the user as a short bulleted list.
4. Fix at least one issue (pick the most impactful). If none are worth fixing, say so and explain why.
5. After any fixes, proceed with `/commit`.
