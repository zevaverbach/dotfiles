-- Leader keys must be set before any plugins/keymaps load
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Suppress noisy LSP/format warnings. `M.notify_impl` is swapped to
-- nvim-notify once that plugin loads (see lua/plugins/notify.lua).
local M = {}

M.notify_impl = vim.notify

local function filtered_notify(msg, level, opts)
  if type(msg) == 'string' then
    if msg:match 'position encoding' or msg:match 'offset_encoding' or msg:match 'client.supports_method' then
      return
    end
    if msg:match 'formatters unavailable' or msg:match 'Client tailwindcss quit' or msg:match 'W325: Ignoring swapfile' then
      return
    end
  end
  return M.notify_impl(msg, level, opts)
end
vim.notify = filtered_notify

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
vim.opt.autoread = true
vim.opt.splitright = true
vim.opt.splitbelow = true

vim.opt.foldmethod = 'manual'
vim.opt.viewoptions = { 'folds', 'cursor', 'curdir', 'slash', 'unix' }

vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
vim.opt.inccommand = 'split'
vim.opt.cursorline = true
vim.opt.scrolloff = 10
vim.opt.hlsearch = true

-- Platform/path helpers shared with other config modules
function M.is_windows()
  return vim.fn.has 'win32' == 1 or vim.fn.has 'win64' == 1
end

function M.joinpath(...)
  if vim.fs and vim.fs.joinpath then
    return vim.fs.joinpath(...)
  end
  return table.concat({ ... }, '/')
end

-- Auto-detect Python virtual environment (activated env or project-local venv)
local function python_from_venv(venv_dir)
  if not venv_dir or venv_dir == '' then
    return nil
  end
  local python_rel = M.is_windows() and { 'Scripts', 'python.exe' } or { 'bin', 'python' }
  local python_path = M.joinpath(venv_dir, unpack(python_rel))
  if vim.fn.filereadable(python_path) == 1 then
    return python_path
  end
  return nil
end

local function is_blocked_python(path)
  if not path or path == '' then
    return false
  end
  local lower = path:lower()
  return lower:match '%.bat$' ~= nil or lower:match '%.cmd$' ~= nil
end

local function find_project_venv(root_dir)
  for _, name in ipairs { '.venv', 'venv', '.env', 'env' } do
    local python_path = python_from_venv(M.joinpath(root_dir, name))
    if python_path then
      return python_path
    end
  end
  return nil
end

local function get_python_path(root_dir)
  local python_path = python_from_venv(vim.env.VIRTUAL_ENV or vim.env.CONDA_PREFIX)
  if python_path and not is_blocked_python(python_path) then
    return python_path
  end

  python_path = find_project_venv(root_dir or vim.fn.getcwd())
  if python_path and not is_blocked_python(python_path) then
    return python_path
  end

  for _, candidate in ipairs { 'python', 'python3' } do
    local exe = vim.fn.exepath(candidate)
    if exe ~= '' and not is_blocked_python(exe) then
      return exe
    end
  end

  return M.is_windows() and 'python' or 'python3'
end

vim.g.python3_host_prog = get_python_path()

vim.api.nvim_create_autocmd('DirChanged', {
  callback = function()
    vim.g.python3_host_prog = get_python_path()
  end,
})

return M
