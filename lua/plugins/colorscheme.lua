return {
  'thesimonho/kanagawa-paper.nvim',
  lazy = false,
  priority = 1000,
  config = function()
    local theme = require 'config.theme'

    vim.cmd.colorscheme(theme.desired_name())

    vim.keymap.set('n', '<leader>t', function()
      vim.cmd.colorscheme(theme.is_light() and theme.dark or theme.light)
    end, { desc = 'Toggle light/dark theme' })

    -- Light-mode highlight tweaks
    local function apply_light_overrides()
      if not theme.is_light() then
        return
      end
      local bg = vim.api.nvim_get_hl(0, { name = 'Normal' }).bg
      vim.api.nvim_set_hl(0, 'LineNr', { fg = vim.api.nvim_get_hl(0, { name = 'LineNr' }).fg, bg = bg })
      vim.api.nvim_set_hl(0, 'CursorLineNr', { fg = vim.api.nvim_get_hl(0, { name = 'CursorLineNr' }).fg, bg = bg })
      vim.api.nvim_set_hl(0, 'Visual', { bg = '#5bb8f0', fg = '#ffffff' })
      vim.api.nvim_set_hl(0, 'Search', { bg = '#ffe44d', fg = '#333333' })
      vim.api.nvim_set_hl(0, 'IncSearch', { bg = '#ffe44d', fg = '#333333', bold = true })
      vim.api.nvim_set_hl(0, 'CurSearch', { bg = '#ffe44d', fg = '#333333', bold = true })
    end

    apply_light_overrides()
    vim.api.nvim_create_autocmd('ColorScheme', { callback = apply_light_overrides })

    -- Poll the override file so an in-progress Neovim session picks up alt+ctrl+t
    -- toggles made in Windows Terminal without needing a restart.
    local last_mtime = nil
    local timer = vim.uv.new_timer()
    timer:start(
      2000,
      2000,
      vim.schedule_wrap(function()
        local stat = vim.uv.fs_stat(theme.state_file)
        local mtime = stat and stat.mtime and stat.mtime.sec or nil
        if mtime ~= last_mtime then
          last_mtime = mtime
          local target = theme.desired_name()
          if vim.g.colors_name ~= target then
            vim.cmd.colorscheme(target)
          end
        end
      end)
    )
  end,
}
