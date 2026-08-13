return {
  'neovim/nvim-lspconfig',
  dependencies = {
    { 'williamboman/mason.nvim', config = true },
    'williamboman/mason-lspconfig.nvim',
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    { 'j-hui/fidget.nvim', opts = {} },
    'hrsh7th/cmp-nvim-lsp',
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
    -- Silence LSP log messages that would otherwise trigger "Press ENTER"
    vim.lsp.handlers['window/logMessage'] = function() end

    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
      callback = function(event)
        local map = function(keys, func, desc)
          vim.keymap.set('n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
        end

        map('gd', function()
          vim.lsp.buf.definition {
            on_list = function(options)
              -- Prefer project files over site-packages overloads
              local project = vim.tbl_filter(function(item)
                return not item.filename:match 'site%-packages'
              end, options.items)
              if #project > 0 then
                options.items = project
              end
              -- Set a single jumplist mark, then navigate without extra entries
              vim.cmd "normal! m'"
              if #options.items == 1 then
                local item = options.items[1]
                vim.cmd('keepjumps drop ' .. vim.fn.fnameescape(item.filename))
                vim.api.nvim_win_set_cursor(0, { item.lnum, (item.col or 1) - 1 })
                vim.cmd 'normal! zv'
              else
                vim.fn.setqflist({}, ' ', options)
                require('telescope.builtin').quickfix()
              end
            end,
          }
        end, '[G]oto [D]efinition')

        map('gi', function()
          vim.lsp.buf.code_action()
        end, 'Import item under cursor')

        map('<leader>r', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
        map('<leader>s', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
        map('<leader>n', vim.lsp.buf.rename, 'Re[n]ame')
        map('<leader>o', vim.lsp.buf.code_action, 'Code [A]ction')
        map('K', vim.lsp.buf.hover, 'Hover Documentation')
      end,
    })

    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())
    -- Set default offset encoding to suppress deprecation warnings
    capabilities.general = capabilities.general or {}
    capabilities.general.positionEncodings = { 'utf-16', 'utf-8' }
    capabilities.workspace = capabilities.workspace or {}
    capabilities.workspace.didChangeWatchedFiles = { dynamicRegistration = false }

    local function is_blocked_cmd(path)
      return path:lower():find('\\nvim%-data\\mason\\', 1, false) ~= nil
    end

    local function resolve_cmd(preferred_path, fallback)
      if preferred_path and preferred_path ~= '' and vim.fn.filereadable(preferred_path) == 1 then
        if not is_blocked_cmd(preferred_path) then
          return preferred_path
        end
      end

      if not fallback or fallback == '' then
        return nil
      end

      local path = vim.fn.exepath(fallback)
      if path == '' or is_blocked_cmd(path) then
        return nil
      end

      return path
    end

    local servers = {
      html = {},
      css_variables = {},
      zls = {},
      gopls = {},
      lua_ls = {
        settings = {
          Lua = {
            completion = {
              callSnippet = 'Replace',
            },
          },
        },
      },
    }

    local tailwind_cmd = resolve_cmd(nil, 'tailwindcss-language-server')
    if tailwind_cmd then
      servers.tailwindcss = {
        cmd = { tailwind_cmd, '--stdio' },
        root_markers = {
          'tailwind.config.js',
          'tailwind.config.cjs',
          'tailwind.config.mjs',
          'tailwind.config.ts',
          'postcss.config.js',
          'postcss.config.cjs',
          'postcss.config.mjs',
        },
        single_file_support = false,
      }
    end

    require('mason').setup()

    local ensure_installed = vim.tbl_keys(servers or {})
    vim.list_extend(ensure_installed, { 'stylua' })
    require('mason-tool-installer').setup { ensure_installed = ensure_installed }

    require('mason-lspconfig').setup {
      -- Prevent mason-lspconfig from auto-enabling every installed server.
      -- We'll configure and start only the servers we explicitly set up below.
      automatic_enable = false,
    }

    for server_name, server in pairs(servers) do
      server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
      vim.lsp.config(server_name, server)
      vim.lsp.enable(server_name)
    end

    -- Python LSP, when available on PATH.
    local pyright_cmd = resolve_cmd(nil, 'pyright-langserver')
    if pyright_cmd then
      vim.lsp.config('pyright', {
        cmd = { pyright_cmd, '--stdio' },
        capabilities = capabilities,
      })
      vim.lsp.enable 'pyright'
    end

    local ts_ls_cmd = resolve_cmd(nil, 'typescript-language-server')
    if ts_ls_cmd then
      local inlay_hints = {
        includeInlayParameterNameHints = 'all',
        includeInlayParameterNameHintsWhenArgumentMatchesName = true,
        includeInlayFunctionParameterTypeHints = true,
        includeInlayVariableTypeHints = true,
        includeInlayPropertyDeclarationTypeHints = true,
        includeInlayFunctionLikeReturnTypeHints = true,
        includeInlayEnumMemberValueHints = true,
      }

      vim.lsp.config('ts_ls', {
        cmd = { ts_ls_cmd, '--stdio' },
        capabilities = capabilities,
        handlers = {
          -- Filter out annoying JSX diagnostics when React types aren't available
          ['textDocument/publishDiagnostics'] = function(err, result, ctx, config)
            if result and result.diagnostics then
              result.diagnostics = vim.tbl_filter(function(diagnostic)
                return diagnostic.code ~= 2875 and diagnostic.code ~= 7026 and diagnostic.code ~= 2503
              end, result.diagnostics)
            end
            vim.lsp.diagnostic.on_publish_diagnostics(err, result, ctx, config)
          end,
        },
        init_options = { preferences = inlay_hints },
        settings = {
          typescript = { inlayHints = inlay_hints },
          javascript = { inlayHints = inlay_hints },
        },
      })
      vim.lsp.enable 'ts_ls'
    end
  end,
}
