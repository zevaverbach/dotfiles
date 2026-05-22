return {
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    opts = {
      ensure_installed = {
        'python',
        'typescript',
        'bash',
        'c',
        'diff',
        'hcl',
        'html',
        'lua',
        'luadoc',
        'markdown',
        'terraform',
        'vim',
        'vimdoc',
      },
      auto_install = true,
      highlight = { enable = true },
      indent = { enable = true },
    },
    config = function(_, opts)
      require('nvim-treesitter.install').prefer_git = true
      require('nvim-treesitter.configs').setup(opts)
    end,
  },
  {
    'stevearc/aerial.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    opts = {
      on_attach = function(bufnr)
        vim.keymap.set('n', '[[', '<cmd>AerialPrev<CR>', { buffer = bufnr })
        vim.keymap.set('n', ']]', '<cmd>AerialNext<CR>', { buffer = bufnr })
      end,
    },
  },
}
