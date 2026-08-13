return {
  {
    'nvim-treesitter/nvim-treesitter',
    -- The `main` branch is the rewrite required for Neovim 0.12+.
    -- `master` is frozen and only supports Nvim 0.10/0.11.
    branch = 'main',
    lazy = false, -- main does not support lazy-loading
    build = ':TSUpdate',
    config = function()
      require('nvim-treesitter').setup()

      -- Parsers to keep installed. `install` is async and a no-op for
      -- parsers that are already present, so it is safe to call on startup.
      require('nvim-treesitter').install {
        'bash',
        'c',
        'cpp',
        'diff',
        'go',
        'html',
        'lua',
        'luadoc',
        'markdown',
        'markdown_inline',
        'python',
        'rust',
        'tsx',
        'typescript',
        'vim',
        'vimdoc',
      }

      -- On `main`, highlighting and indentation are opt-in per buffer.
      -- Guard with pcall so a filetype without an installed parser simply
      -- gets no treesitter features instead of throwing (which used to
      -- disable the highlighter and drop the buffer to monochrome).
      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('treesitter-start', { clear = true }),
        callback = function(ev)
          if pcall(vim.treesitter.start, ev.buf) then
            vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },
}
