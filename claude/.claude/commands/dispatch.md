---
description: Dispatch a task to a new tmux window with impl + review panes
argument-hint: <filepath> <item_id>
---

Dispatch a task from a project file to a new tmux window with two Claude Code sessions.

## Input

`$ARGUMENTS` — two arguments: `{filepath} {item_id}` (e.g., `plans/PROJECT_MANAGER.md 8b`). Both are required.

## Steps

1. Read the specified file and find the section whose heading matches `## {item_id}.` or `## {item_id} ` (e.g., `## 8b.` for input "8b").

2. Extract:
   - The **full heading title** (e.g., "Session JWT revocation on role change / member removal")
   - The **prompt text** inside the ` ```prompt ``` ` code fence in that section

3. Derive a **short window name**: `{item_id}-{kebab-case-title}` truncated to ~30 chars (e.g., `8b-jwt-revocation`).

4. Create the tmux layout using Bash. IMPORTANT — handle quoting carefully since prompts may contain special characters:
   - Write the extracted prompt to a temp file: `mktemp /tmp/dispatch-prompt-XXXX`
   - Create a new tmux window **without changing focus**: `tmux new-window -d -c {project_dir} -n '{window_name}'`
   - In the left pane, launch claude reading the prompt from the temp file:
     `tmux send-keys -t '{window_name}' -l "claude --dangerously-skip-permissions \"\$(cat {tempfile})\""`
     then `tmux send-keys -t '{window_name}' Enter`
   - Split horizontally: `tmux split-window -d -h -c {project_dir} -t '{window_name}'`
   - In the right pane, start claude: send `claude --dangerously-skip-permissions` + Enter
   - Wait ~6 seconds for claude to initialize
   - Pre-fill (WITHOUT pressing Enter) just the command prefix so the user can type the title:
     `tmux send-keys -t '{window_name}.1' -l 'review-impl '`

5. Report to the user:
   - The new tmux window name
   - What's running in each pane
   - Remind them the window will highlight red in the status bar when the implementation session stops for input
