-- Theme names and the light/dark resolution shared by the colorscheme and
-- statusline plugin specs.
local options = require 'config.options'

local M = {}

M.dark = 'kanagawa-paper-ink'
M.light = 'kanagawa-paper-canvas'

-- Durable override written by wt-toggle-theme.ps1 (bound to alt+ctrl+t in Windows
-- Terminal). When present and valid ('light' or 'dark'), this takes precedence over
-- the time-of-day default below.
M.state_file = options.joinpath(vim.fn.stdpath 'state', 'theme')

local function read_override()
  local f = io.open(M.state_file, 'r')
  if not f then
    return nil
  end
  local content = f:read '*l'
  f:close()
  if content then
    content = content:gsub('%s+', '')
  end
  if content == 'light' or content == 'dark' then
    return content
  end
  return nil
end

local function compute_default_mode()
  local hour = tonumber(os.date '%H')
  local minute = tonumber(os.date '%M')
  return (hour < 12 or (hour == 12 and minute < 30)) and 'light' or 'dark'
end

function M.desired_name()
  return (read_override() or compute_default_mode()) == 'light' and M.light or M.dark
end

function M.is_light()
  return vim.g.colors_name == M.light
end

return M
