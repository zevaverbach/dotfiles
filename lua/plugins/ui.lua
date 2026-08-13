return {
  {
    'stevearc/dressing.nvim',
    event = 'VeryLazy',
    -- Only wrap vim.ui.input (rename prompts etc.). vim.ui.select is left for
    -- telescope-ui-select so list pickers get fuzzy search.
    opts = { select = { enabled = false } },
  },
  {
    -- Collection of various small independent plugins/modules.
    -- Note: mini.notify is intentionally not used — notifications go through
    -- the filtering wrapper in config.options backed by nvim-notify.
    'echasnovski/mini.nvim',
    config = function()
      -- Better Around/Inside textobjects
      --  - va)  - [V]isually select [A]round [)]paren
      --  - yinq - [Y]ank [I]nside [N]ext [']quote
      --  - ci'  - [C]hange [I]nside [']quote
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
