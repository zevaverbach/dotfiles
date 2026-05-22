return {
  'neovim/nvim-lspconfig',
  dependencies = {
    { 'williamboman/mason.nvim', config = true },
    'williamboman/mason-lspconfig.nvim',
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    { 'j-hui/fidget.nvim', opts = {} },
    {
      'folke/lazydev.nvim',
      ft = 'lua',
      opts = {
        library = {
          { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
        },
      },
    },
  },
  config = function()
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
      callback = function(event)
        local map = function(keys, func, desc)
          vim.keymap.set('n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
        end

        map('gd', function()
          require('telescope.builtin').lsp_definitions()
        end, '[G]oto [D]efinition')

        map('gi', function()
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if not client then
            return
          end
          local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
          client:request('textDocument/definition', params, function(err, result)
            if err or not result or vim.tbl_isempty(result) then
              -- No definition found — trigger completion so the LSP can offer an auto-import
              vim.lsp.completion.trigger()
            end
          end, 0)
        end, 'Import item under cursor')

        map('<leader>r', function()
          require('telescope.builtin').lsp_references {
            layout_config = {
              horizontal = {
                prompt_position = 'top',
                preview_width = 0.6,
                results_width = 0.4,
                width = 0.95,
                height = 0.95,
              },
            },
            path_display = { 'tail' },
            fname_width = 50,
          }
        end, '[G]oto [R]eferences')

        map('<leader>s', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
        map('<leader>n', vim.lsp.buf.rename, 'Re[n]ame')
        map('<leader>o', vim.lsp.buf.code_action, 'Code [A]ction')
        -- K (hover) is provided by Neovim's default LSP keymaps in 0.10+.

        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if not client then
          return
        end

        if client:supports_method('textDocument/documentHighlight', event.buf) then
          local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
          vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.document_highlight,
          })
          vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.clear_references,
          })
        end

        -- Built-in LSP completion (replaces nvim-cmp)
        if client:supports_method('textDocument/completion', event.buf) then
          vim.lsp.completion.enable(true, client.id, event.buf, { autotrigger = true })
        end
      end,
    })

    -- Registered once (not inside LspAttach) so multiple clients share the same detach handler
    vim.api.nvim_create_autocmd('LspDetach', {
      group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
      callback = function(event)
        vim.lsp.buf.clear_references()
        vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event.buf }
      end,
    })

    local capabilities = vim.lsp.protocol.make_client_capabilities()

    local servers = {
      pyright = {},
      ts_ls = {},
      html = {},
      tailwindcss = {},
      css_variables = {},
      terraformls = {},

      lua_ls = {
        settings = {
          Lua = {
            completion = { callSnippet = 'Replace' },
          },
        },
      },
    }

    require('mason').setup()

    local ensure_installed = vim.tbl_keys(servers or {})
    vim.list_extend(ensure_installed, { 'stylua' })
    require('mason-tool-installer').setup { ensure_installed = ensure_installed }

    vim.lsp.config('*', { capabilities = capabilities })
    for server_name, server_opts in pairs(servers) do
      vim.lsp.config(server_name, server_opts)
    end

    require('mason-lspconfig').setup {
      ensure_installed = vim.tbl_keys(servers),
    }
  end,
}
