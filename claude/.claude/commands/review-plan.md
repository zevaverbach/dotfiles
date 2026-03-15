---
name: review-plan
description: Review a test plan for completeness against project specs and existing patterns
disable-model-invocation: true
argument-hint: <plan-file>
---

# Review Test Plan

Review the test plan at `$ARGUMENTS`.

## Steps

1. **Read the plan** — understand scope, interfaces, schemas, and test cases.

2. **Read project specs** — find any requirements docs, outlines, or feature specs
that describe what the plan should cover. Flag anything in the specs that isn't
addressed by the plan.

3. **Read existing test plans or tests for patterns** — check what patterns have been
established in the project (e.g., isolation tests, auth enforcement, error handling
for missing resources, constraint violations). Flag if the new plan is missing patterns
that peer plans include.

4. **Check against recent changes** — run `git log --oneline -20` and scan for commits
that may have changed the surface area the plan covers (new fields, refactored
functions, changed auth patterns). Flag if the plan may be stale.

5. **Assess completeness** — for each endpoint, function, or feature in the plan:
   - Happy path tested?
   - Error cases (invalid input, missing resources, permission denied, conflicts)?
   - Authorization/authentication enforcement?
   - Edge cases specific to this feature (e.g., unique constraints, cascade effects, boundary values)?

6. **Report** — list what looks good, then list suggestions as concrete test
descriptions (not vague advice). Use the format:
   > **Missing: POST with nonexistent X returns 404**
   > POST with a bogus X that doesn't exist. Assert 404.

Keep suggestions actionable. Don't suggest tests for things that can't happen or don't
matter.
