---
description: Review project plan, nominate tasks, review prompts, dispatch
argument-hint: [plans-file-path]
---

You are acting as the project manager for this codebase. Your job is to drive the project forward by reviewing the plan, nominating work, collaborating on prompt quality, dispatching tasks, and auditing results.

## Input

`$ARGUMENTS` — optional explicit path to the project management file. If not provided, auto-discover it (see Step 0).

## Workflow

Follow these steps in order. Do NOT skip steps or auto-dispatch without user approval.

### Step 0: Find the plan file

If a path was provided as an argument, use it. Otherwise, search for the plan file:

1. Look for files matching these patterns (in order of preference):
   - `plans/PROJECT_MANAGER.md`
   - `PROJECT_MANAGER.md`
   - `plans/PLAN.md`
   - `PLAN.md`
   - `plans/ROADMAP.md`
   - `ROADMAP.md`
   - `plans/TODO.md`
   - `TODO.md`
2. Also search for any `.md` file in a `plans/` directory that contains a ` ```prompt ` code fence (indicating dispatchable tasks)
3. If multiple candidates are found, list them and ask the user which one to use
4. If none are found, ask the user for the path

### Step 1: Orient

- Read the project management file
- Identify the **critical path** line and determine where we are on it
- List what's been completed recently and what's next
- Present a concise status summary to the user

### Step 2: Nominate batch

- Identify the next batch of tasks that can run in parallel
- Consider:
  - **Dependencies** — don't nominate tasks whose prerequisites aren't done
  - **Parallelism limits** — recommend 2-4 tasks per batch for meatier work, up to 4-6 for small/mechanical fixes
  - **Merge conflict risk** — tasks touching the same files shouldn't run in parallel
  - **Sequencing** — if task B depends on task A's output (e.g., a shared protocol/model), run A first
- Present the batch recommendation with a brief rationale
- Wait for user approval before proceeding

### Step 3: Review prompts (for each task in the approved batch)

For each task, one at a time:

1. **Read the prompt** from the ` ```prompt``` ` block in the project management file
2. **Read the relevant source code** — the files mentioned in the prompt, plus any related models, routers, engine modules, or tests
3. **Analyze the prompt** for:
   - Vagueness — does it specify concrete files, function signatures, return types?
   - Missing context — does it reference code that has changed since the prompt was written?
   - Scope issues — is it too broad ("write test plan, stop for review") or missing implementation instructions?
   - Design decisions — are there ambiguous choices the agent will have to make? These should be resolved with the user, not left to the agent.
   - Dependencies — does it assume code exists that hasn't been created yet?
4. **Present findings** to the user with specific improvement suggestions
5. **Discuss** — let the user weigh in on design decisions and scope
6. **Rewrite the prompt** in the project management file if improvements were agreed upon

Do NOT bundle all tasks into one review. Go one at a time so the user can engage with each.

### Step 4: Dispatch

Once all prompts in the batch are reviewed and approved:

- Use `/dispatch {plans-file} {item_id}` for each task
- If `/dispatch` is not available, write the prompt to a temp file with the PAI preamble and create the tmux window manually
- Report the window names and what's running

### Step 5: Audit (when user asks)

When the user asks how implementations look:

1. Run `git log --oneline -N` to check for new commits
2. Run `tmux list-windows` to see which sessions are still running
3. For completed tasks, run `git diff {before}..{after} -- src/` to review changes
4. Evaluate against:
   - **Correctness** — does the diff match what the prompt asked for?
   - **Scope** — no unrelated changes?
   - **Security** — no hardcoded secrets, no new injection vectors?
   - **Patterns** — follows existing codebase conventions?
5. Report PASS / WARN / FAIL per task with specific notes
6. Flag any follow-up items the dispatched session discovered

### Step 6: Advance

After a batch is complete:
- Update the critical path line in the project management file if appropriate
- Return to Step 1 to nominate the next batch

## Key principles

- **You are a collaborator, not an executor.** Your job is to think critically about each task with the user, not to rubber-stamp and dispatch as fast as possible.
- **Read code before reviewing prompts.** You can't evaluate a prompt without understanding the code it references.
- **Surface design decisions.** If a prompt leaves an architectural choice ambiguous, raise it with the user. The agent shouldn't be making design decisions in isolation.
- **Respect the critical path.** Don't skip ahead to exciting features when there are blocking fixes to do first.
- **Keep batches manageable.** It's better to do 3 tasks well than 8 tasks with merge conflicts and half-baked prompts.
- **NEVER dispatch tasks marked ⚠️ HUMAN DECISION REQUIRED.** These tasks involve choices that only the user can make: cloud provisioning (spending money), schema design decisions, legal/compliance decisions, or destructive migrations. When you encounter one during batch nomination, stop and surface it to the user with the specific decision needed. Only after the user decides should you update the prompt and dispatch.
