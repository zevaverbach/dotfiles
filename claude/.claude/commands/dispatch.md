---
description: Dispatch a task to a new tmux window with a Claude Code session
argument-hint: <filepath> <item_id>
---

Dispatch a task from a project file to a new tmux window with a Claude Code session.

## Input

`$ARGUMENTS` — two arguments: `{filepath} {item_id}` (e.g., `plans/PROJECT_MANAGER.md 8b`). Both are required.

## Steps

1. Read the specified file and find the section whose heading matches `## {item_id}.` or `## {item_id} ` (e.g., `## 8b.` for input "8b").

2. Extract:
   - The **full heading title** (e.g., "Session JWT revocation on role change / member removal")
   - The **prompt text** inside the ` ```prompt ``` ` code fence in that section

3. Derive a **short window name**: `{item_id}-{kebab-case-title}` truncated to ~30 chars (e.g., `8b-jwt-revocation`).

4. Create the tmux window using Bash. IMPORTANT — handle quoting carefully since prompts may contain special characters:
   - Write the extracted prompt to a temp file: `mktemp /tmp/dispatch-prompt-XXXX`
   - **Prepend a PAI preamble** to the temp file before the task prompt, so the dispatched session operates as PAI (not raw Claude Code). The preamble should be:
     ```
     You are PAI. Read ~/.claude/CLAUDE.md for your operating instructions, then read ~/.claude/PAI/USER/AISTEERINGRULES.md for personal behavioral rules. Operate in the appropriate PAI mode for the task below.

     PARALLEL SESSION RULE: Multiple Claude Code sessions may be running on the same branch. During development, only run tests scoped to your task (specific test files or describe/it blocks). Run the full test suite only as a final validation when your task is complete. Never run DB migrations, seeds, or full builds without checking for lock contention.

     Now execute:

     ---

     ```
     followed by the extracted prompt text.
   - Create a new tmux window **without changing focus**: `tmux new-window -d -c {project_dir} -n '{window_name}'`
   - Launch claude reading the prompt from the temp file:
     `tmux send-keys -t '{window_name}' -l " claude --dangerously-skip-permissions \"\$(cat {tempfile})\"; printf '\\a'"`
     then `tmux send-keys -t '{window_name}' Enter`

5. Report to the user:
   - The new tmux window name
   - What task is running
   - Remind them the window will highlight red in the status bar when the session stops for input

6. **Post-execution audit.** When the user reports that a dispatched session has finished (or you are asked to review it), run the following in the project directory:
   - `git diff` — review all uncommitted changes made by the dispatched session
   - `git log --oneline -10` — check for any commits it made
   - Evaluate the diff against PAI's safety rules:
     - **No destructive actions** taken without justification (deleted files, dropped resources, force pushes)
     - **No security issues** introduced (hardcoded secrets, exposed credentials, injection vectors)
     - **Minimal scope** — changes are scoped to the dispatched task, no unrelated modifications
     - **No unintended side effects** on shared state (migrations, config changes, dependency modifications)
   - Report a summary: what changed, any concerns flagged, and a PASS/WARN/FAIL verdict
   - If WARN or FAIL: list specific issues and recommend whether to keep, revert, or amend the changes
