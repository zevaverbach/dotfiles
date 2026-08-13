return {
  'SmiteshP/nvim-navbuddy',
  dependencies = {
    'SmiteshP/nvim-navic',
    'MunifTanjim/nui.nvim',
  },
  keys = {
    { '<leader>y', '<cmd>Navbuddy<CR>', desc = 'Navbuddy symbol tree' },
  },
  config = function()
    local navbuddy = require 'nvim-navbuddy'
    local actions = require 'nvim-navbuddy.actions'

    navbuddy.setup {
      lsp = { auto_attach = true },
      window = {
        size = '85%',
      },
      mappings = {
        ['<C-c>'] = actions.close(),
      },
      node_markers = {
        enabled = true,
        icons = {
          leaf = '* ',
          leaf_selected = '> ',
          branch = '+ ',
        },
      },
    }
  end,
}
