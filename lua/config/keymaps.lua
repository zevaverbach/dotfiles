local options = require 'config.options'

-- Clear search highlight; insert-mode Esc
vim.keymap.set('n', '<C-c>', '<cmd>nohlsearch<CR>')
vim.keymap.set('i', '<C-c>', '<Esc>', { noremap = true, silent = true })

-- Oil file browser
vim.keymap.set('n', '-', '<CMD>Oil<CR>', { desc = 'Open parent directory' })

-- System clipboard
vim.keymap.set('v', '<leader>y', '"+y', { noremap = true, silent = true, desc = 'Yank to system clipboard' })
vim.keymap.set('n', '<leader>m', 'ggVG"+y', { noremap = true, silent = true, desc = 'Copy whole buffer to system clipboard' })

-- Theme toggle
vim.keymap.set('n', '<leader>t', options.toggle_theme, { desc = 'Toggle dark/light theme' })

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

-- Open init.lua
vim.keymap.set('n', '<leader>v', '<cmd>e ~/.config/nvim/init.lua<cr>', { desc = 'open init.lua' })

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

-- gf: create non-existent files (and parent dirs) on the fly
vim.keymap.set('n', 'gf', function()
  local path = vim.fn.expand '<cfile>'
  if path == '' then
    return
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

  vim.cmd('edit ' .. vim.fn.fnameescape(path))
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
