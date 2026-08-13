---
task: Fix broken Go diagnostics in Neovim
slug: 20260813-145026_fix-nvim-golang-diagnostics
effort: standard
phase: complete
progress: 12/12
mode: interactive
started: 2026-08-13T18:50:26Z
updated: 2026-08-13T19:05:00Z
---

## Context

Zev reports Go diagnostics stopped working in Neovim. Evidence gathered:

- `nvim --headless main.go` → `CLIENTS=0` (no LSP attaches to a .go buffer)
- `vim.lsp.is_enabled('gopls')` → **false**, while `lua_ls`, `ts_ls`, `pyright` → **true**
- gopls IS installed (Mason v0.22.0) and resolvable: `vim.fn.exepath('gopls')` → `~/.local/share/nvim/mason/bin/gopls`
- LSP log shows gopls working normally on 2026-08-08, silent since
- `~/repos/dotfiles/init.lua:789-793` calls `require('mason-lspconfig').setup { automatic_enable = false }`, then explicitly enables only the servers in its own local `servers` table (html, css_variables, zls, lua_ls, +tailwindcss) plus pyright and ts_ls. **gopls is absent from that list.**
- `git diff` shows this entire LSP block is an *uncommitted* re-inlining of config back into init.lua; gopls was dropped in the process.
- `require('lazy').setup({...})` at init.lua:447 has no `{ import = 'plugins' }`, so `lua/plugins/lsp.lua` (which DOES list gopls) is never loaded — dead code.

Root cause: gopls is configured nowhere that actually executes, and `automatic_enable = false` removed the safety net that used to start it.

### Risks
- Adding gopls to `servers` also adds it to `mason-tool-installer` ensure_installed (derived from `vim.tbl_keys(servers)`) — acceptable, gopls is already installed.
- `capabilities` is force-merged into each server entry; an empty `{}` table is the same shape lua_ls/html use, so no new failure mode.
- Must not remove `automatic_enable = false` — that is a deliberate choice to avoid starting every installed server.

## Criteria

- [x] ISC-1: `gopls` key added to init.lua servers table
- [x] ISC-2: `vim.lsp.config('gopls', ...)` executes at startup
- [x] ISC-3: `vim.lsp.is_enabled('gopls')` returns true
- [x] ISC-4: gopls client attaches to a .go buffer
- [x] ISC-5: gopls cmd resolves to Mason binary path
- [x] ISC-6: Diagnostics published for a deliberately broken Go file
- [x] ISC-7: `lua_ls` remains enabled after change
- [x] ISC-8: `ts_ls` remains enabled after change
- [x] ISC-9: `pyright` remains enabled after change
- [x] ISC-10: No new startup errors in `:messages`
- [x] ISC-11: gopls present in mason-tool-installer ensure_installed
- [x] ISC-A1: `automatic_enable = false` line not removed
- [x] ISC-A2: `lua/plugins/lsp.lua` not deleted or modified

## Decisions

## Verification
- ISC-1..2: `git diff init.lua` shows single added line `gopls = {},` at servers table (init.lua:753)
- ISC-3: headless probe → `gopls enabled=true`
- ISC-4: headless probe on main.go → `CLIENTS=1  attached: gopls  root=/Users/zev/repos/learn-go-2026/make-a-cli`
- ISC-5: `vim.fn.exepath('gopls')` → `/Users/zev/.local/share/nvim/mason/bin/gopls` (Mason PATH injection active)
- ISC-6: broken temp Go file → `DIAGNOSTIC_COUNT=2`: "declared and not used: unusedVar", "cannot use \"not an int\" (untyped string constant) as int value"
- ISC-7/8/9: lua_ls, ts_ls, pyright, html all still `enabled=true` post-change
- ISC-10: `:messages` contained only probe output, no errors
- ISC-11: gopls now in `vim.tbl_keys(servers)` feeding mason-tool-installer; 'gopls' is the correct Mason package name
- ISC-A1: `automatic_enable = false` intact at init.lua:793
- ISC-A2: lua/plugins/lsp.lua untouched (mtime May 22, unchanged by this session)

### Open finding (not fixed — needs Zev's decision)
`require('lazy').setup({...})` at init.lua:447 has no `{ import = 'plugins' }`, so the whole modularized `lua/plugins/` tree — including `lua/plugins/lsp.lua`, which correctly lists gopls — is dead code. The uncommitted working tree re-inlined everything into init.lua. This is a rearchitecting decision, deliberately left alone.
