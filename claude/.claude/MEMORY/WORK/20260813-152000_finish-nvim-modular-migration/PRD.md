---
task: Finish Neovim modular config migration
slug: 20260813-152000_finish-nvim-modular-migration
effort: advanced
phase: complete
progress: 14/14
mode: interactive
started: 2026-08-13T19:20:00Z
updated: 2026-08-13T19:06:48Z
---

## Context

Follow-on from [gopls fix]. Zev chose to finish the half-applied modularization rather than
restore HEAD (which would have dropped 20 plugins) or naively add an import (which would have
let lua/plugins/lsp.lua override the working LSP block).

Merge policy adopted: **preserve current runtime behavior** — the 1725-line monolith is what
Zev actually runs — while keeping the refactor's genuine 0.12-era improvements
(treesitter `main` branch, telescope/oil/conform/gitsigns rewrites, vim.diagnostic.jump,
go/c indent autocmds, clangd compile-db warning, dressing.nvim).

Monolith backed up to /tmp/init.lua.monolith.backup before the switch.

## Criteria

- [x] ISC-1: init.lua reduced to 4-line delegator
- [x] ISC-2: lua/config/lazy.lua import path active
- [x] ISC-3: gopls attaches to .go buffers
- [x] ISC-4: Go diagnostics publish correctly
- [x] ISC-5: All 20 missing plugins ported into lua/plugins/
- [x] ISC-6: nvim-cmp completion stack loads
- [x] ISC-7: kanagawa-paper colorscheme active (not catppuccin)
- [x] ISC-8: lualine loads with custom sections
- [x] ISC-9: nvim-notify wired to the filtering wrapper
- [x] ISC-10: Monolith-only keymaps restored
- [x] ISC-11: Monolith-only autocmds restored
- [x] ISC-12: Python venv detection restored
- [x] ISC-13: Zero startup errors
- [x] ISC-14: Monolith backed up before overwrite

## Decisions

- **nvim-cmp over vim.lsp.completion** — the refactor had migrated to built-in completion;
  reverted to cmp to preserve what Zev runs today. The experiment stays in git history.
- **kanagawa-paper over catppuccin** — kanagawa is the live theme with elaborate light/dark
  polling and lualine theming; catppuccin was refactor-only and was dropped.
- **nvim-notify over mini.notify** — same reasoning; the filtering wrapper in config.options
  forwards to nvim-notify via `M.notify_impl`.
- **nvim-treesitter-textobjects dropped** — incompatible with the `main` branch of
  nvim-treesitter that the refactor adopted. The `af`/`if`/`ac`/`ic` textobject maps are gone.
- **navbuddy `lsp.auto_attach = true` restored** — the monolith declared it in the dependency
  spec but a later setup() call silently dropped it. Merged into one setup.
- New shared module lua/config/theme.lua holds theme names + light/dark resolution, used by
  both colorscheme.lua and lualine.lua.

## Verification

- `GO_CLIENTS=1 (gopls)`; broken Go file → `DIAGNOSTIC_COUNT=2` with correct messages
- `STARTUP_ERRORS=0`; `PLUGINS_SPECED=37 LOADED=26` (rest are lazy-loaded by event/ft)
- `colorscheme=kanagawa-paper-ink`
- require() succeeds for lualine, cmp, luasnip, notify, navbuddy, telescope, oil, gitsigns,
  conform, lint, Comment, todo-comments, mini.ai, fidget
- Keymaps present: `<leader>t` `<leader>x` `<leader>\`` `<leader>b` `<leader>l` `gf` `,d`;
  `<C-q>` confirmed via maparg (normalized to `<C-Q>`)
- Go buffer indent: `expandtab=false tabstop=4`
- Lazy clean removed: catppuccin, nvim-treesitter-textobjects, friendly-snippets (was commented out)
