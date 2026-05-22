-- Leader keys must be set before any plugins/keymaps load
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.opt.cmdheight = 0
vim.g.loaded_sql_completion = 1
vim.g.omni_sql_no_default_maps = 1
vim.g.have_nerd_font = true

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = 'a'
vim.opt.showmode = false
vim.opt.breakindent = true
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.signcolumn = 'yes'
vim.opt.updatetime = 1000
vim.opt.splitright = true
vim.opt.splitbelow = true

vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
vim.opt.inccommand = 'split'
vim.opt.cursorline = true
vim.opt.scrolloff = 10
vim.opt.hlsearch = true

-- Built-in LSP completion: menu even for single match, no auto-select, show doc popup
vim.opt.completeopt = { 'menu', 'menuone', 'noselect', 'popup' }

-- Theme state and toggle
local theme_env = (os.getenv 'NVIM_THEME' or os.getenv 'NVIM_BACKGROUND' or ''):lower()
local M = {}
M.theme_is_light = theme_env == 'light' or theme_env == 'day' or theme_env == 'latte'
vim.api.nvim_set_option_value('background', M.theme_is_light and 'light' or 'dark', {})

function M.toggle_theme()
  M.theme_is_light = not M.theme_is_light
  vim.api.nvim_set_option_value('background', M.theme_is_light and 'light' or 'dark', {})
end

return M
