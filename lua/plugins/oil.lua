return {
  'stevearc/oil.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  opts = {
    natural_order = false,
    keymaps = {
      ['<C-s>'] = false,
    },
    sort = {
      { 'ctime', 'desc' },
    },
    view_options = {
      show_hidden = true,
    },
  },
}
