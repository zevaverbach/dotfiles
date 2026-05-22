---
description: Create a new slash command in the dotfiles repo
argument-hint: <command-name> <description>
---

Create a new Claude Code slash command.

## Input

`$ARGUMENTS` — two arguments: `{command-name} {description}` (e.g., `my-command "Does something useful"`).

## Steps

1. Parse the command name from the first argument. Validate it's kebab-case (lowercase, hyphens only, no spaces).

2. Determine the commands directory. Check if `~/.claude/commands` is a symlink — if so, resolve it to get the real directory (likely in a dotfiles repo). Write the file there directly (no per-file symlink needed).

3. Create the command file at `{commands-dir}/{command-name}.md` with this template:

   ```
   ---
   description: {description}
   argument-hint: <args>
   ---

   {description}

   ## Input

   `$ARGUMENTS`

   ## Steps

   1. [TODO: Define what this command does]
   ```

4. Report to the user:
   - The file path (for editing)
   - Remind them to edit the command file to define its behavior
