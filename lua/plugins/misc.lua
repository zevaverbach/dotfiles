return {
  -- Detect tabstop and shiftwidth automatically
  'tpope/vim-sleuth',

  'sindrets/diffview.nvim',

  {
    'numToStr/Comment.nvim',
    opts = {
      -- Enable multiline comments
      mappings = {
        basic = true,
        extra = true,
      },
      pre_hook = nil,
      post_hook = nil,
    },
  },

  -- Highlight todo, notes, etc in comments
  {
    'folke/todo-comments.nvim',
    event = 'VimEnter',
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = { signs = false },
  },

  -- Subtle Markdown enhancements (no layout reflow)
  {
    'lukas-reineke/headlines.nvim',
    dependencies = 'nvim-treesitter/nvim-treesitter',
    ft = { 'markdown', 'norg', 'org', 'rmd' },
    opts = {
      markdown = {
        headline_highlights = { 'Headline1', 'Headline2', 'Headline3', 'Headline4', 'Headline5', 'Headline6' },
        fat_headlines = false,
      },
    },
  },
}
