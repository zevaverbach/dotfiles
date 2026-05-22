return {
  'nvim-telescope/telescope.nvim',
  event = 'VimEnter',
  branch = '0.1.x',
  dependencies = {
    'nvim-lua/plenary.nvim',
    {
      'nvim-telescope/telescope-fzf-native.nvim',
      build = 'make',
      cond = function()
        return vim.fn.executable 'make' == 1
      end,
    },
    { 'nvim-telescope/telescope-ui-select.nvim' },
    {
      'nvim-telescope/telescope-live-grep-args.nvim',
      version = '^1.0.0',
    },
  },
  config = function()
    local telescope = require 'telescope'
    local actions = require 'telescope.actions'
    telescope.setup {
      defaults = {
        layout_config = {
          horizontal = {
            prompt_position = 'top',
            preview_width = 0.6,
            results_width = 0.4,
            width = 0.95,
            height = 0.95,
          },
        },
        sorting_strategy = 'ascending',
        file_ignore_patterns = {},
        results_title = false,
        dynamic_preview_title = true,
        mappings = {
          i = { ['<C-q>'] = actions.send_to_qflist + actions.open_qflist },
          n = { ['<C-q>'] = actions.send_to_qflist + actions.open_qflist },
        },
      },
      extensions = {
        ['ui-select'] = { require('telescope.themes').get_dropdown() },
        live_grep_args = { auto_quoting = true },
      },
    }
    telescope.load_extension 'live_grep_args'
    pcall(telescope.load_extension, 'fzf')
    pcall(telescope.load_extension, 'ui-select')

    local builtin = require 'telescope.builtin'
    vim.keymap.set('n', '<leader>f', builtin.find_files, { desc = '[S]earch [F]iles' })
    vim.keymap.set('n', '<leader>g', function()
      builtin.live_grep {
        additional_args = function()
          return { '--ignore-case' }
        end,
      }
    end, { desc = '[S]earch by [G]rep' })
  end,
}
