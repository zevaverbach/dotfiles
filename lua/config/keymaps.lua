local options = require 'config.options'

-- Clear search highlight; insert-mode Esc
vim.keymap.set('n', '<C-c>', '<cmd>nohlsearch<CR>')
vim.keymap.set('i', '<C-c>', '<Esc>', { noremap = true, silent = true })

-- Oil file browser
vim.keymap.set('n', '-', '<CMD>Oil<CR>', { desc = 'Open parent directory' })

-- System clipboard
vim.keymap.set('n', '<leader>c', '"+y', { noremap = true, silent = true })
vim.keymap.set('v', '<leader>y', '"+y', { noremap = true, silent = true, desc = 'Yank to system clipboard' })
vim.keymap.set('n', '<leader>m', 'ggVG"+y', { noremap = true, silent = true, desc = 'Copy whole buffer to system clipboard' })
vim.keymap.set('n', '<C-d>', 'dd', { noremap = true, silent = true })

vim.keymap.set('n', '<leader>p', function()
  vim.fn.setreg('+', vim.fn.expand '%:p')
  vim.notify('Copied path to current buffer', vim.log.levels.INFO)
end, { noremap = true, silent = true, desc = 'Copy buffer path to clipboard' })

-- Diffview
vim.keymap.set('n', ',d', '<cmd>DiffviewOpen<cr>', { desc = 'Repo diff' })
vim.keymap.set('n', ',hh', '<cmd>DiffviewFileHistory<cr>', { desc = 'Repo history' })
vim.keymap.set('n', ',hf', '<cmd>DiffviewFileHistory --follow %<cr>', { desc = 'File history' })

-- Diagnostics
vim.keymap.set('n', '[d', function()
  vim.diagnostic.jump { count = -1, float = true }
end, { desc = 'Go to previous [D]iagnostic message' })
vim.keymap.set('n', ']d', function()
  vim.diagnostic.jump { count = 1, float = true }
end, { desc = 'Go to next [D]iagnostic message' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostic [E]rror messages' })

-- Save / quit / buffer nav
vim.keymap.set('n', '<C-s>', '<cmd>w<CR>', { desc = 'Save' })
vim.keymap.set('n', '<leader>q', '<cmd>wqa<CR>', { desc = 'Save and Quit' })
vim.keymap.set('n', '<C-h>', '<cmd>bp<CR>', { desc = 'Prev Buffer' })
vim.keymap.set('n', '<C-l>', '<cmd>bn<CR>', { desc = 'Next Buffer' })
vim.keymap.set('n', '<leader>w', '<cmd>write|bdelete<cr>', { desc = 'Save and close' })

-- Quickfix navigation
vim.keymap.set('n', ']n', ':cnext<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '[n', ':cprev<CR>', { noremap = true, silent = true })

-- Move lines up/down
vim.keymap.set('v', '<C-k>', ":m '<-2<CR>gv=gv", { noremap = true, silent = true })
vim.keymap.set('v', '<C-j>', ":m '>+1<CR>gv=gv", { noremap = true, silent = true })
vim.keymap.set('n', '<C-k>', ':m -2<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<C-j>', ':m +1<CR>', { noremap = true, silent = true })

-- Open the Neovim config
vim.keymap.set('n', '<leader>v', function()
  vim.cmd('edit ' .. vim.fn.fnameescape(vim.fn.stdpath 'config' .. '/init.lua'))
end, { desc = 'open vim config' })

-- Toggle git blame
vim.keymap.set('n', '<leader>b', function()
  local ok, gs = pcall(require, 'gitsigns')
  if not ok then
    vim.notify('gitsigns not loaded', vim.log.levels.WARN)
    return
  end
  gs.toggle_current_line_blame()
  local cfg = require('gitsigns.config').config
  vim.notify('Blame: ' .. (cfg.current_line_blame and 'ON' or 'OFF'))
end, { desc = 'Toggle git blame' })

-- Open most recently modified file
vim.keymap.set('n', '<leader>l', function()
  local files = vim.fn.systemlist [[
    find . -type f \
      -not -path '*/\.*' \
      -not -path '*_cache/*' \
      -not -path '*/__pycache__/*' \
      -not -name '*.pyc' \
      -not -name 'pyproject.toml' \
      -not -name 'poetry.lock' \
      -not -name '*.db' \
      -printf '%T@ %p\n' | sort -n | tail -1 | cut -f2- -d" "
  ]]

  if #files > 0 and files[1] ~= '' then
    vim.cmd('edit ' .. vim.fn.fnameescape(files[1]))
  else
    vim.notify('No files found.', vim.log.levels.WARN)
  end
end, { desc = 'Open latest modified file' })

-- C-q closes quickfix if open, otherwise visual-block
local function close_quickfix_or_default()
  for _, win in pairs(vim.fn.getwininfo()) do
    if win.quickfix == 1 then
      vim.cmd 'cclose'
      return
    end
  end
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-v>', true, false, true), 'n', false)
end
vim.keymap.set('n', '<C-q>', close_quickfix_or_default, { desc = 'Close quickfix or visual block mode' })

-- ── Checklist / checkbox toggles ────────────────────────────────────────────

local function normalize_range(start_line, end_line)
  if start_line > end_line then
    return end_line, start_line
  end
  return start_line, end_line
end

local function map_lines(start_line, end_line, fn)
  start_line, end_line = normalize_range(start_line, end_line)
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  for i, line in ipairs(lines) do
    lines[i] = fn(line)
  end
  vim.api.nvim_buf_set_lines(0, start_line - 1, end_line, false, lines)
end

local function toggle_task_or_header_line(line)
  local indent, rest = line:match '^(%s*)(.*)$'
  if rest:match '^%- %[.%] ' then
    rest = rest:gsub('^%- %[.%] ', '- ', 1)
  elseif rest:match '^%- ' then
    rest = rest:gsub('^%- ', '- [ ] ', 1)
  else
    rest = '- [ ] ' .. rest
  end
  return indent .. rest
end

local function toggle_checkbox_line(line)
  local indent, rest = line:match '^(%s*)(.*)$'
  if rest:match '^%- %[[xX]%] ' then
    rest = rest:gsub('^%- %[[xX]%] ', '- [ ] ', 1)
  elseif rest:match '^%- %[%s%] ' then
    rest = rest:gsub('^%- %[%s%] ', '- [x] ', 1)
  else
    return line
  end
  return indent .. rest
end

function _G.toggle_task_or_header_operator(_)
  map_lines(vim.fn.line "'[", vim.fn.line "']", toggle_task_or_header_line)
end

function _G.toggle_checkbox_operator(_)
  map_lines(vim.fn.line "'[", vim.fn.line "']", toggle_checkbox_line)
end

vim.keymap.set('n', '<leader>h', function()
  vim.go.operatorfunc = 'v:lua.toggle_task_or_header_operator'
  return 'g@_'
end, { expr = true, desc = 'Toggle between checklist and bullet' })

vim.keymap.set('v', '<leader>h', function()
  vim.go.operatorfunc = 'v:lua.toggle_task_or_header_operator'
  return 'g@'
end, { expr = true, desc = 'Toggle between checklist and bullet' })

vim.keymap.set('n', '<leader>x', function()
  vim.go.operatorfunc = 'v:lua.toggle_checkbox_operator'
  local count = vim.v.count1
  if count == 1 then
    return 'g@_'
  end
  return 'g@' .. (count - 1) .. 'j'
end, { expr = true, desc = 'Toggle checkbox' })

vim.keymap.set('v', '<leader>x', function()
  vim.go.operatorfunc = 'v:lua.toggle_checkbox_operator'
  return 'g@'
end, { expr = true, desc = 'Toggle checkbox' })

-- ── Backtick toggling around dot-delimited words ────────────────────────────

local backtick_pairs = {
  ['('] = ')',
  ['['] = ']',
  ['{'] = '}',
  ['<'] = '>',
  ['"'] = '"',
  ["'"] = "'",
  ['`'] = '`',
}

local function toggle_backticks_on_line(line)
  local word_start, word_end = line:find '[%w_]+%.[%w_%.]*'
  if not word_start then
    return line
  end

  local char_before = word_start > 1 and line:sub(word_start - 1, word_start - 1) or ''
  local char_after = word_end < #line and line:sub(word_end + 1, word_end + 1) or ''

  if backtick_pairs[char_before] == char_after then
    if char_before == '`' then
      return line:sub(1, word_start - 2) .. line:sub(word_start, word_end) .. line:sub(word_end + 2)
    end
    return line:sub(1, word_start - 2) .. '`' .. line:sub(word_start, word_end) .. '`' .. line:sub(word_end + 2)
  end

  return line:sub(1, word_start - 1) .. '`' .. line:sub(word_start, word_end) .. '`' .. line:sub(word_end + 1)
end

local function toggle_backticks_at_cursor()
  local line = vim.fn.getline '.'
  if line == '' then
    return
  end

  local col = math.min(math.max(vim.fn.col '.', 1), math.max(#line, 1))

  local function is_word_char(ch)
    return ch:match '[%w_%.]' ~= nil
  end

  if not is_word_char(line:sub(col, col)) then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('ysiw`', true, false, true), 'm', false)
    return
  end

  local word_start = col
  while word_start > 1 and is_word_char(line:sub(word_start - 1, word_start - 1)) do
    word_start = word_start - 1
  end

  local word_end = col
  while word_end < #line and is_word_char(line:sub(word_end + 1, word_end + 1)) do
    word_end = word_end + 1
  end

  local char_before = word_start > 1 and line:sub(word_start - 1, word_start - 1) or ''
  local char_after = word_end < #line and line:sub(word_end + 1, word_end + 1) or ''

  local updated
  if backtick_pairs[char_before] == char_after then
    if char_before == '`' then
      updated = line:sub(1, word_start - 2) .. line:sub(word_start, word_end) .. line:sub(word_end + 2)
    else
      updated = line:sub(1, word_start - 2) .. '`' .. line:sub(word_start, word_end) .. '`' .. line:sub(word_end + 2)
    end
  else
    updated = line:sub(1, word_start - 1) .. '`' .. line:sub(word_start, word_end) .. '`' .. line:sub(word_end + 1)
  end
  vim.api.nvim_set_current_line(updated)
end

function _G.toggle_backticks_operator(_)
  local start = vim.fn.getpos "'["
  local finish = vim.fn.getpos "']"
  local start_line, end_line = start[2], finish[2]

  if start_line == 0 or end_line == 0 then
    toggle_backticks_at_cursor()
    return
  end

  if start_line == end_line then
    local line = vim.api.nvim_buf_get_lines(0, start_line - 1, start_line, false)[1] or ''
    local col0 = math.min(math.max(start[3] - 1, 0), math.max(#line - 1, 0))
    vim.api.nvim_win_set_cursor(0, { start_line, col0 })
    toggle_backticks_at_cursor()
    vim.api.nvim_win_set_cursor(0, { start_line, col0 })
    return
  end

  map_lines(start_line, end_line, toggle_backticks_on_line)
end

local function toggle_backticks_visual_selection()
  local start = vim.fn.getpos "'<"
  local finish = vim.fn.getpos "'>"
  local start_line, start_col = start[2], start[3]
  local end_line, end_col = finish[2], finish[3]

  if start_line == 0 or end_line == 0 then
    return
  end

  if start_line > end_line or (start_line == end_line and start_col > end_col) then
    start_line, end_line = end_line, start_line
    start_col, end_col = end_col, start_col
  end

  if start_line ~= end_line then
    map_lines(start_line, end_line, toggle_backticks_on_line)
    return
  end

  local line = vim.api.nvim_buf_get_lines(0, start_line - 1, start_line, false)[1] or ''
  if line == '' then
    return
  end

  local s = math.max(1, start_col)
  local e = math.min(end_col, #line)
  if s > e then
    return
  end

  local sel = line:sub(s, e)
  if #sel >= 2 and sel:sub(1, 1) == '`' and sel:sub(-1) == '`' then
    vim.api.nvim_set_current_line(line:sub(1, s - 1) .. sel:sub(2, -2) .. line:sub(e + 1))
    return
  end

  local before = s > 1 and line:sub(s - 1, s - 1) or ''
  local after = e < #line and line:sub(e + 1, e + 1) or ''
  if before == '`' and after == '`' then
    vim.api.nvim_set_current_line(line:sub(1, s - 2) .. sel .. line:sub(e + 2))
    return
  end

  vim.api.nvim_set_current_line(line:sub(1, s - 1) .. '`' .. sel .. '`' .. line:sub(e + 1))
end

vim.keymap.set('n', '<leader>`', function()
  vim.go.operatorfunc = 'v:lua.toggle_backticks_operator'
  return 'g@l'
end, { expr = true, desc = 'Toggle backticks around dot-delimited word' })

vim.keymap.set('v', '<leader>`', function()
  toggle_backticks_visual_selection()
  vim.cmd 'normal! \\<Esc>'
end, { desc = 'Toggle backticks around selection' })

-- ── gf: follow URLs, else open (creating if needed) the path under cursor ────

local function scan_under_cursor(pattern, prefix)
  local line = vim.fn.getline '.'
  local col = vim.fn.col '.'
  local start = 0
  while true do
    local match = vim.fn.matchstrpos(line, pattern, start)
    local text, s, e = match[1], match[2], match[3]
    if s == -1 or text == '' then
      return nil
    end
    if col >= s + 1 and col <= e then
      text = text:gsub('[%.,;:%)%]%}]+$', '')
      return prefix and (prefix .. text) or text
    end
    start = e + 1
  end
end

local function url_under_cursor()
  return scan_under_cursor [[\vhttps?://[^ \t\r\n"'<>]+]] or scan_under_cursor([[\vwww\.[^ \t\r\n"'<>]+]], 'https://')
end

local function path_under_cursor()
  return scan_under_cursor [[\v[A-Za-z]:[\\/][^ \t\r\n"'<>|]+]]
    or scan_under_cursor [[\v\\\\[A-Za-z0-9_.-]+\\[^ \t\r\n"'<>|]+]]
    or vim.fn.expand '<cfile>'
end

local function open_url(url)
  if vim.ui and vim.ui.open and pcall(vim.ui.open, url) then
    return
  end

  if options.is_windows() then
    vim.fn.jobstart('cmd.exe /c start "" "' .. url:gsub('"', '\\"') .. '"', { detach = true })
    return
  end

  for _, opener in ipairs { 'xdg-open', 'open' } do
    if vim.fn.executable(opener) == 1 then
      vim.fn.jobstart({ opener, url }, { detach = true })
      return
    end
  end
end

vim.keymap.set('n', 'gf', function()
  local url = url_under_cursor()
  if url then
    open_url(url)
    return
  end

  local path = path_under_cursor()
  if path == '' then
    return
  end

  -- Normalize Windows paths so :edit doesn't treat backslashes as escapes.
  path = path:gsub('\\', '/')
  if path:match '^%a:[^/]' then
    path = path:gsub('^(%a):', '%1:/', 1)
  end

  if vim.fn.filereadable(path) == 0 then
    local dir = vim.fn.fnamemodify(path, ':h')
    if dir ~= '.' and vim.fn.isdirectory(dir) == 0 then
      vim.fn.mkdir(dir, 'p')
    end
    local file = io.open(path, 'w')
    if file then
      file:close()
    end
  end

  vim.cmd { cmd = 'edit', args = { path } }
end, { noremap = true })

-- Emacs-style command-line editing
vim.cmd [[
cnoremap <C-a> <Home>
cnoremap <C-e> <End>
cnoremap <C-b> <Left>
cnoremap <C-f> <Right>
cnoremap <C-d> <Del>
cnoremap <C-h> <BS>
cnoremap <C-k> <C-\>e(strpart(getcmdline(), 0, getcmdpos() - 1))<CR>
cnoremap <C-u> <C-\>e""<CR>
]]
