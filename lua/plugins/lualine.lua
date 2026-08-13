return {
  'nvim-lualine/lualine.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    local theme = require 'config.theme'

    -- Custom light-mode lualine theme: yellow + baby blue with white text
    local light_lualine_theme = {
      normal = {
        a = { bg = '#ffe44d', fg = '#ffffff', gui = 'bold' },
        b = { bg = '#5bb8f0', fg = '#ffffff' },
        c = { bg = '#e8e8e8', fg = '#444444' },
      },
      insert = { a = { bg = '#5bb8f0', fg = '#ffffff', gui = 'bold' } },
      visual = { a = { bg = '#ffe44d', fg = '#ffffff', gui = 'bold' } },
      replace = { a = { bg = '#ffe44d', fg = '#ffffff', gui = 'bold' } },
      command = { a = { bg = '#5bb8f0', fg = '#ffffff', gui = 'bold' } },
      inactive = {
        a = { bg = '#d0d0d0', fg = '#888888' },
        b = { bg = '#d0d0d0', fg = '#888888' },
        c = { bg = '#e8e8e8', fg = '#888888' },
      },
    }

    local function current_lualine_theme()
      return theme.is_light() and light_lualine_theme or 'auto'
    end

    local function oil_relative_dir()
      if vim.bo.filetype == 'oil' then
        return require('oil').get_current_dir() or ''
      end
      return ''
    end

    local function repo_relative_path()
      local filepath = vim.fn.expand '%:p'
      if filepath == '' then
        return ''
      end
      local cwd = vim.fn.getcwd()
      if cwd:sub(-1) == '/' then
        cwd = cwd:sub(1, -2)
      end
      return (filepath:gsub('^' .. vim.pesc(cwd) .. '/', ''))
    end

    local sections = {
      lualine_a = { 'mode' },
      lualine_b = { 'branch', 'diff', 'diagnostics' },
      lualine_c = {
        {
          repo_relative_path,
          cond = function()
            return vim.bo.filetype ~= 'oil'
          end,
        },
        oil_relative_dir,
      },
      lualine_x = {},
      lualine_y = { 'progress' },
      lualine_z = { 'location' },
    }

    local function setup()
      require('lualine').setup {
        options = { theme = current_lualine_theme() },
        sections = sections,
        tabline = {},
      }
    end

    setup()

    -- Refresh the lualine theme when the colorscheme changes
    vim.api.nvim_create_autocmd('ColorScheme', { callback = setup })
  end,
}
