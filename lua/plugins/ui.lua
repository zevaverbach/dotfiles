return {
  {
    'rcarriga/nvim-notify',
    opts = {
      render = 'minimal',
      timeout = 3000,
      background_colour = 'Normal',
      merge_duplicates = true,
    },
  },
  {
    'stevearc/dressing.nvim',
    event = 'VeryLazy',
    opts = {},
  },
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    priority = 1000,
    config = function()
      local flavor = vim.go.background == 'light' and 'latte' or 'mocha'
      vim.cmd('colorscheme catppuccin-' .. flavor)
      vim.cmd.hi 'Comment gui=none'
    end,
  },
  {
    'echasnovski/mini.nvim',
    config = function()
      require('mini.ai').setup { n_lines = 500 }

      local statusline = require 'mini.statusline'
      statusline.setup { use_icons = vim.g.have_nerd_font }

      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_location = function()
        return '%2l:%-2v'
      end

      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_git = function()
        return ''
      end
    end,
  },
}
