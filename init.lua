-- TODO: make it so `gc` toggles comments in a multiline selection
-- TODO: make it so `leader-n` brings up rename with the current name highlighting so it gets replaced
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.opt.cmdheight = 0
vim.g.loaded_sql_completion = 1
vim.g.omni_sql_no_default_maps = 1
vim.g.have_nerd_font = true
-- Make line numbers default
vim.opt.number = true
vim.opt.relativenumber = true
-- Enable mouse mode, can be useful for resizing splits for example!
vim.opt.mouse = 'a'
-- Don't show the mode, since it's already in the status line
vim.opt.showmode = false
vim.opt.breakindent = true
vim.opt.undofile = true
-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.ignorecase = true
vim.opt.smartcase = true
-- Keep signcolumn on by default
vim.opt.signcolumn = 'yes'
-- Decrease update time
vim.opt.updatetime = 1000
-- Configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true
local theme_env = (os.getenv 'NVIM_THEME' or os.getenv 'NVIM_BACKGROUND' or ''):lower()
local theme_is_light = theme_env == 'light' or theme_env == 'day' or theme_env == 'latte'
vim.api.nvim_set_option_value('background', theme_is_light and 'light' or 'dark', {})

-- Sets how neovim will display certain whitespace characters in the editor.
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
-- Preview substitutions live, as you type!
vim.opt.inccommand = 'split'
-- Show which line your cursor is on
vim.opt.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 10
-- Set python host only if poetry is available and in a poetry project
local function has_poetry_pyproject(path)
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then
    return false
  end
  for _, line in ipairs(lines) do
    if line:match('^%s*%[tool%.poetry%]%s*$') then
      return true
    end
  end
  return false
end

if vim.fn.executable('poetry') == 1 and vim.fn.filereadable('pyproject.toml') == 1 and has_poetry_pyproject('pyproject.toml') then
  local poetry_path = vim.fn.system('poetry env info --path'):gsub('%s+$', '')
  if poetry_path ~= '' then
    vim.g.python3_host_prog = poetry_path .. '/bin/python'
  end
end

vim.opt.hlsearch = true
vim.keymap.set('n', '<C-c>', '<cmd>nohlsearch<CR>')
vim.keymap.set('i', '<C-c>', '<Esc>', { noremap = true, silent = true })
vim.keymap.set('n', '-', '<CMD>Oil<CR>', { desc = 'Open parent directory' })
vim.keymap.set('n', '<leader>c', '"+y', { noremap = true, silent = true })
vim.keymap.set('v', '<leader>y', '"+y', { noremap = true, silent = true })
vim.keymap.set('n', '<C-d>', 'dd', { noremap = true, silent = true })
-- vim.keymap.set('n', ',d', '<cmd>DiffviewOpen<cr>', { desc = 'Repo diff' })
-- vim.keymap.set('n', ',hh', '<cmd>DiffviewFileHistory<cr>', { desc = 'Repo history' })
-- vim.keymap.set('n', ',hf', '<cmd>DiffviewFileHistory --follow %<cr>', { desc = 'File history' })
vim.keymap.set('n', '<leader>m', 'ggVG"+y', { noremap = true, silent = true })
-- Set quickfix window to open on the right with 30% of screen width
local function resize_quickfix()
  for _, win in pairs(vim.fn.getwininfo()) do
    if win.quickfix == 1 then
      local screen_width = vim.o.columns
      local qf_width = math.floor(screen_width * 0.3)
      vim.api.nvim_win_call(win.winid, function()
        vim.cmd('vertical resize ' .. qf_width)
      end)
      break
    end
  end
end

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'qf',
  callback = function()
    -- Move quickfix window to the right
    vim.cmd 'wincmd L'
    resize_quickfix()
  end,
})

-- Resize quickfix when terminal is resized
vim.api.nvim_create_autocmd('VimResized', {
  callback = resize_quickfix,
})

-- save last position
vim.api.nvim_create_autocmd('BufRead', {
  callback = function(opts)
    vim.api.nvim_create_autocmd('BufWinEnter', {
      once = true,
      buffer = opts.buf,
      callback = function()
        local ft = vim.bo[opts.buf].filetype
        local last_known_line = vim.api.nvim_buf_get_mark(opts.buf, '"')[1]
        if not (ft:match 'commit' and ft:match 'rebase') and last_known_line > 1 and last_known_line <= vim.api.nvim_buf_line_count(opts.buf) then
          vim.api.nvim_feedkeys([[g`"]], 'nx', false)
        end
      end,
    })
  end,
})

-- Set Go-specific tab settings
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'go',
  callback = function()
    vim.opt_local.tabstop = 4       -- Display tabs as 4 spaces wide
    vim.opt_local.shiftwidth = 4    -- Indent with 4 spaces worth
    vim.opt_local.softtabstop = 4   -- Tab key inserts 4 spaces worth
    vim.opt_local.expandtab = false -- Keep tabs as tabs, don't convert to spaces
  end,
})

-- Diagnostic keymaps
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous [D]iagnostic message' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next [D]iagnostic message' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostic [E]rror messages' })
-- vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

vim.keymap.set('n', '<C-s>', '<cmd>w<CR>', { desc = 'Save' })
-- save all buffers and quit
vim.keymap.set('n', '<leader>q', '<cmd>wqa<CR>', { desc = 'Save and Quit' })
vim.keymap.set('n', '<C-h>', '<cmd>bp<CR>', { desc = 'Prev Buffer' })
vim.keymap.set('n', '<C-l>', '<cmd>bn<CR>', { desc = 'Next Buffer' })
vim.keymap.set('n', '<leader>w', '<cmd>write|bdelete<cr>', { desc = 'Save and close' })
-- Function to go to the next item in the quickfix list
vim.keymap.set('n', ']n', ':cnext<CR>', { noremap = true, silent = true })

-- Function to go to the previous item in the quickfix list
vim.keymap.set('n', '[n', ':cprev<CR>', { noremap = true, silent = true })
-- Visual mode mappings
vim.keymap.set('v', '<C-k>', ":m '<-2<CR>gv=gv", { noremap = true, silent = true })
vim.keymap.set('v', '<C-j>', ":m '>+1<CR>gv=gv", { noremap = true, silent = true })
-- Normal mode mappings
vim.keymap.set('n', '<C-k>', ':m -2<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<C-j>', ':m +1<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>v', '<cmd>e ~/.config/nvim/init.lua<cr>', { desc = 'open init.lua' })

-- Close quickfix list with C-q if it exists, otherwise use default C-q behavior
local function close_quickfix_or_default()
  local qf_exists = false
  for _, win in pairs(vim.fn.getwininfo()) do
    if win.quickfix == 1 then
      qf_exists = true
      break
    end
  end
  if qf_exists then
    vim.cmd 'cclose'
  else
    -- Use default C-q behavior (visual block mode)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-v>', true, false, true), 'n', false)
  end
end

vim.keymap.set('n', '<C-q>', close_quickfix_or_default, { desc = 'Close quickfix or visual block mode' })

-- [[ Basic Autocommands ]]
-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- [[ Install `lazy.nvim` plugin manager ]]
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
end ---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)

-- NOTE: Here is where you install your plugins.
require('lazy').setup({
  'rcarriga/nvim-notify',
  'tpope/vim-sleuth', -- Detect tabstop and shiftwidth automatically
  -- 'sindrets/diffview.nvim',
  {
    'github/copilot.vim',
    init = function()
      if os.getenv 'DISABLE_COPILOT' then
        -- Disable copilot entirely
        vim.g.copilot_enabled = false
      else
        vim.g.copilot_filetypes = {
          markdown = false,
          text = false,
        }
      end
    end,
  },

  {
    'stevearc/oil.nvim',
    opts = {},
    -- Optional dependencies
    dependencies = { 'nvim-tree/nvim-web-devicons' },
  },
  {
    'numToStr/Comment.nvim',
    opts = {
      -- Enable multiline comments
      mappings = {
        basic = true,
        extra = true,
      },
      -- Pre-hook function to execute before commenting
      pre_hook = nil,
      -- Post-hook function to execute after commenting
      post_hook = nil,
    },
  },

  { -- Adds git related signs to the gutter, as well as utilities for managing changes
    'lewis6991/gitsigns.nvim',
    opts = {
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { '‾' },
        changedelete = { text = '~' },
      },
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
        delay = 1000,
        ignore_whitespace = false,
      },
      current_line_blame_formatter = '<author>, <author_time:%R> - <summary>',
      -- Add on_attach function to set up keymaps
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns

        -- Create a variable to track the current base state
        local is_dev_base = false
        local is_master_base = false

        -- Function to toggle between default (HEAD) and dev branch comparison
        local function toggle_base_to_dev()
          if is_dev_base then
            -- Reset to default (HEAD)
            gs.change_base(nil)
            is_dev_base = false
            vim.notify 'Gitsigns: Comparing against HEAD'
          else
            -- Change to dev branch
            gs.change_base 'dev'
            is_dev_base = true
            vim.notify 'Gitsigns: Comparing against dev branch'
          end
        end

        local function toggle_base_to_master()
          if is_master_base then
            -- Reset to default (HEAD)
            gs.change_base(nil)
            is_master_base = false
            vim.notify 'Gitsigns: Comparing against HEAD'
          else
            -- Change to master branch
            gs.change_base 'master'
            is_master_base = true
            vim.notify 'Gitsigns: Comparing against master branch'
          end
        end

        -- Set up the keybinding for toggling the base
        vim.keymap.set('n', '<leader>tb', toggle_base_to_dev, { buffer = bufnr, desc = 'Toggle git diff base between HEAD and dev' })
        vim.keymap.set('n', '<leader>tm', toggle_base_to_master, { buffer = bufnr, desc = 'Toggle git diff base between HEAD and master' })

        -- You can add other keymaps here as needed
        -- Navigation between hunks
        vim.keymap.set('n', ']c', function()
          if vim.wo.diff then
            return ']c'
          end
          vim.schedule(function()
            gs.next_hunk()
          end)
          return '<Ignore>'
        end, { expr = true, buffer = bufnr })

        vim.keymap.set('n', '[c', function()
          if vim.wo.diff then
            return '[c'
          end
          vim.schedule(function()
            gs.prev_hunk()
          end)
          return '<Ignore>'
        end, { expr = true, buffer = bufnr })
      end,
    },
  },

  { -- Fuzzy Finder (files, lsp, etc)
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
      -- Useful for getting pretty icons, but requires a Nerd Font.
      -- waiting for Windows Terminal to support this
      -- { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
      {
        'nvim-telescope/telescope-live-grep-args.nvim',
        -- For major updates, this must be adjusted manually.
        version = '^1.0.0',
      },
    },
    config = function()
      local telescope = require 'telescope'
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
            i = {
              ['<C-q>'] = require('telescope.actions').send_to_qflist + require('telescope.actions').open_qflist,
            },
            n = {
              ['<C-q>'] = require('telescope.actions').send_to_qflist + require('telescope.actions').open_qflist,
            },
          },
        },
        extensions = {
          ['ui-select'] = {
            require('telescope.themes').get_dropdown(),
          },
          live_grep_args = {
            auto_quoting = true,
          },
        },
      }
      telescope.load_extension 'live_grep_args'

      -- Enable Telescope extensions if they are installed
      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'ui-select')

      -- See `:help telescope.builtin`
      local builtin = require 'telescope.builtin'
      vim.keymap.set('n', '<leader>f', builtin.find_files, { desc = '[S]earch [F]iles' })
      vim.keymap.set('n', '<leader>g', function()
        require('telescope.builtin').live_grep {
          additional_args = function()
            return { '--ignore-case' } -- Always case-insensitive
          end,
        }
      end, { desc = '[S]earch by [G]rep' })

      vim.keymap.set('n', '<leader>d', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
      vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
      vim.keymap.set('n', '<leader>b', builtin.buffers, { desc = '[ ] Find existing buffers' })
    end,
  },

  { -- LSP Configuration & Plugins
    'neovim/nvim-lspconfig',
    dependencies = {
      -- Automatically install LSPs and related tools to stdpath for Neovim
      { 'williamboman/mason.nvim', config = true }, -- NOTE: Must be loaded before dependants
      'williamboman/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',

      -- Useful status updates for LSP.
      -- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
      { 'j-hui/fidget.nvim', opts = {} },

      -- `neodev` configures Lua LSP for your Neovim config, runtime and plugins
      -- used for completion, annotations and signatures of Neovim apis
      { 'folke/neodev.nvim', opts = {} },
      {
        'SmiteshP/nvim-navbuddy',
        dependencies = {
          'SmiteshP/nvim-navic',
          'MunifTanjim/nui.nvim',
        },
        opts = { lsp = { auto_attach = true } },
      },
    },
    config = function()
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
        callback = function(event)
          -- NOTE: Remember that Lua is a real programming language, and as such it is possible
          -- to define small helper and utility functions so you don't have to repeat yourself.
          --
          -- In this case, we create a function that lets us more easily define mappings specific
          -- for LSP related items. It sets the mode, buffer and description for us each time.
          local map = function(keys, func, desc)
            vim.keymap.set('n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end

          -- Jump to the definition of the word under your cursor.
          --  This is where a variable was first declared, or where a function is defined, etc.
          --  To jump back, press <C-t>.
          map('gd', function()
            require('telescope.builtin').lsp_definitions()
          end, '[G]oto [D]efinition')

          map('gi', function()
            local params = vim.lsp.util.make_position_params()

            vim.lsp.buf_request(0, 'textDocument/definition', params, function(err, result, ctx, config)
              if err or not result or vim.tbl_isempty(result) then
                -- If no definition found, try to trigger completion and auto-import
                vim.lsp.buf.completion {
                  context = {
                    triggerKind = vim.lsp.protocol.CompletionTriggerKind.Invoked,
                  },
                }
              end
            end)
          end, 'Import item under cursor')

          -- Find references for the word under your cursor.
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

          -- Jump to the implementation of the word under your cursor.
          --  Useful when your language has ways of declaring types without an actual implementation.
          -- map('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')

          -- Jump to the type of the word under your cursor.
          --  Useful when you're not sure what type a variable is and you want to see
          --  the definition of its *type*, not where it was *defined*.
          map('<leader>s', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')

          -- Rename the variable under your cursor.
          --  Most Language Servers support renaming across files, etc.
          map('<leader>n', vim.lsp.buf.rename, 'Re[n]ame')

          -- Execute a code action, usually your cursor needs to be on top of an error
          -- or a suggestion from your LSP for this to activate.
          map('<leader>o', vim.lsp.buf.code_action, 'Code [A]ction')

          -- Opens a popup that displays documentation about the word under your cursor
          --  See `:help K` for why this keymap.
          map('K', vim.lsp.buf.hover, 'Hover Documentation')

          -- This is not Goto Definition, this is Goto Declaration.
          --  For example, in C this would take you to the header.
          -- map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

          -- The following two autocommands are used to highlight references of the
          -- word under your cursor when your cursor rests there for a little while.
          --    See `:help CursorHold` for information about when this is executed
          --
          -- When you move your cursor, the highlights will be cleared (the second autocommand).
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client.server_capabilities.documentHighlightProvider then
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

            vim.api.nvim_create_autocmd('LspDetach', {
              group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
              callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
              end,
            })
          end

          -- The following autocommand is used to enable inlay hints in your
          -- code, if the language server you are using supports them
          --
          -- This may be unwanted, since they displace some of your code
          -- if client and client.server_capabilities.inlayHintProvider and vim.lsp.inlay_hint then
          --   map('<leader>th', function()
          --     vim.lsp.inlay_hint.enable(false, nil)
          --   end, '[T]oggle Inlay [H]ints')
          -- end
        end,
      })

      -- LSP servers and clients are able to communicate to each other what features they support.
      --  By default, Neovim doesn't support everything that is in the LSP specification.
      --  When you add nvim-cmp, luasnip, etc. Neovim now has *more* capabilities.
      --  So, we create new capabilities with nvim cmp, and then broadcast that to the servers.
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())

      -- Enable the following language servers
      --  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
      --
      --  Add any additional override configuration in the following tables. Available keys are:
      --  - cmd (table): Override the default command used to start the server
      --  - filetypes (table): Override the default list of associated filetypes for the server
      --  - capabilities (table): Override fields in capabilities. Can be used to disable certain LSP features.
      --  - settings (table): Override the default settings passed when initializing the server.
      --        For example, to see the options for `lua_ls`, you could go to: https://luals.github.io/wiki/settings/
      --
      local servers = {
        pyright = {},
        -- ... etc. See `:help lspconfig-all` for a list of all the pre-configured LSPs
        --
        -- Some languages (like typescript) have entire language plugins that can be useful:
        --    https://github.com/pmizio/typescript-tools.nvim
        --
        -- But for many setups, the LSP (`tsserver`) will work just fine
        ts_ls = {},
        html = {},
        tailwindcss = {},
        css_variables = {},
        terraformls = {},

        lua_ls = {
          -- cmd = {...},
          -- filetypes = { ...},
          -- capabilities = {},
          settings = {
            Lua = {
              completion = {
                callSnippet = 'Replace',
              },
              -- You can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
              -- diagnostics = { disable = { 'missing-fields' } },
            },
          },
        },
      }

      -- Ensure the servers and tools above are installed
      --  To check the current status of installed tools and/or manually install
      --  other tools, you can run
      --    :Mason
      --
      --  You can press `g?` for help in this menu.
      require('mason').setup()

      -- You can add other tools here that you want Mason to install
      -- for you, so that they are available from within Neovim.
      local ensure_installed = vim.tbl_keys(servers or {})
      vim.list_extend(ensure_installed, {
        'stylua', -- Used to format Lua code
      })
      require('mason-tool-installer').setup { ensure_installed = ensure_installed }

      require('mason-lspconfig').setup {
        handlers = {
          function(server_name)
            local server = servers[server_name] or {}
            -- This handles overriding only values explicitly passed
            -- by the server configuration above. Useful when disabling
            -- certain features of an LSP (for example, turning off formatting for tsserver)
            server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
            require('lspconfig')[server_name].setup(server)
          end,
        },
      }
    end,
  },

  { -- Autoformat
    'stevearc/conform.nvim',
    lazy = false,
    opts = {
      notify_on_error = false,
      format_on_save = function(bufnr)
        -- Disable "format_on_save lsp_fallback" for languages that don't
        -- have a well standardized coding style. You can add additional
        -- languages here or re-enable it for the disabled ones.
        local disable_filetypes = { c = true, cpp = true, python = true }
        return {
          timeout_ms = 2500,
          lsp_fallback = not disable_filetypes[vim.bo[bufnr].filetype],
        }
      end,
      log_level = vim.log.levels.DEBUG,
      formatters = {
        prettier = {
          command = 'prettier',
          args = { '--stdin-filepath', '$FILENAME' },
          stdin = true,
        },
        black = {
          prepend_args = { '--line-length', '120' },
        },
      },
      formatters_by_ft = {
        lua = { 'stylua' },
        javascript = { 'prettierd', 'prettier' },
        typescript = { 'prettierd', 'prettier' },
        typescriptreact = { 'prettierd', 'prettier' },
        -- python = { 'black' }, -- Add this line for Python formatting
      },
    },
  },

  { -- Autocompletion
    'hrsh7th/nvim-cmp',
    event = 'InsertEnter',
    dependencies = {
      -- Snippet Engine & its associated nvim-cmp source
      {
        'L3MON4D3/LuaSnip',
        build = (function()
          -- Build Step is needed for regex support in snippets.
          -- This step is not supported in many windows environments.
          -- Remove the below condition to re-enable on windows.
          if vim.fn.has 'win32' == 1 or vim.fn.executable 'make' == 0 then
            return
          end
          return 'make install_jsregexp'
        end)(),
        dependencies = {
          -- `friendly-snippets` contains a variety of premade snippets.
          --    See the README about individual language/framework/plugin snippets:
          --    https://github.com/rafamadriz/friendly-snippets
          -- {
          --   'rafamadriz/friendly-snippets',
          --   config = function()
          --     require('luasnip.loaders.from_vscode').lazy_load()
          --   end,
          -- },
        },
      },
      'saadparwaiz1/cmp_luasnip',

      -- Adds other completion capabilities.
      --  nvim-cmp does not ship with all sources by default. They are split
      --  into multiple repos for maintenance purposes.
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-path',
    },
    config = function()
      -- See `:help cmp`
      local cmp = require 'cmp'
      local luasnip = require 'luasnip'
      luasnip.config.setup {}

      cmp.setup {
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        completion = { completeopt = 'menu,menuone,noinsert' },

        -- For an understanding of why these mappings were
        -- chosen, you will need to read `:help ins-completion`
        --
        -- No, but seriously. Please read `:help ins-completion`, it is really good!
        mapping = cmp.mapping.preset.insert {
          -- Select the [n]ext item
          ['<C-n>'] = cmp.mapping.select_next_item(),
          -- Select the [p]revious item
          ['<C-p>'] = cmp.mapping.select_prev_item(),

          -- Scroll the documentation window [b]ack / [f]orward
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),

          -- Accept ([y]es) the completion.
          --  This will auto-import if your LSP supports it.
          --  This will expand snippets if the LSP sent a snippet.
          ['<C-y>'] = cmp.mapping.confirm { select = true },

          -- If you prefer more traditional completion keymaps,
          -- you can uncomment the following lines
          --['<CR>'] = cmp.mapping.confirm { select = true },
          --['<Tab>'] = cmp.mapping.select_next_item(),
          --['<S-Tab>'] = cmp.mapping.select_prev_item(),

          -- Manually trigger a completion from nvim-cmp.
          --  Generally you don't need this, because nvim-cmp will display
          --  completions whenever it has completion options available.
          ['<C-Space>'] = cmp.mapping.complete {},

          -- Think of <c-l> as moving to the right of your snippet expansion.
          --  So if you have a snippet that's like:
          --  function $name($args)
          --    $body
          --  end
          --
          -- <c-l> will move you to the right of each of the expansion locations.
          -- <c-h> is similar, except moving you backwards.
          ['<C-l>'] = cmp.mapping(function()
            if luasnip.expand_or_locally_jumpable() then
              luasnip.expand_or_jump()
            end
          end, { 'i', 's' }),
          ['<C-h>'] = cmp.mapping(function()
            if luasnip.locally_jumpable(-1) then
              luasnip.jump(-1)
            end
          end, { 'i', 's' }),

          -- For more advanced Luasnip keymaps (e.g. selecting choice nodes, expansion) see:
          --    https://github.com/L3MON4D3/LuaSnip?tab=readme-ov-file#keymaps
        },
        sources = {
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
          { name = 'path' },
        },
      }
    end,
  },

  {
    'catppuccin/nvim',
    name = 'catppuccin',
    priority = 1000,
    config = function()
      local catppuccin_flavor = theme_is_light and 'latte' or 'mocha'
      vim.cmd('colorscheme catppuccin-' .. catppuccin_flavor)
      vim.cmd.hi 'Comment gui=none'
    end,
  },

  -- Highlight todo, notes, etc in comments
  {
    'folke/todo-comments.nvim',
    event = 'VimEnter',
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = { signs = false },
  },
  {
    'kylechui/nvim-surround',
    version = '*', -- Use for stability; omit to use `main` branch for the latest features
    event = 'VeryLazy',
    config = function()
      require('nvim-surround').setup {
        -- Configuration here, or leave empty to use defaults
      }
    end,
  },

  { -- Collection of various small independent plugins/modules
    'echasnovski/mini.nvim',
    config = function()
      -- Better Around/Inside textobjects
      --
      -- Examples:
      --  - va)  - [V]isually select [A]round [)]paren
      --  - yinq - [Y]ank [I]nside [N]ext [']quote
      --  - ci'  - [C]hange [I]nside [']quote
      require('mini.ai').setup { n_lines = 500 }

      -- Simple and easy statusline.
      --  You could remove this setup call if you don't like it,
      --  and try some other statusline plugin
      local statusline = require 'mini.statusline'
      -- set use_icons to true if you have a Nerd Font
      statusline.setup { use_icons = vim.g.have_nerd_font }

      -- You can configure sections in the statusline by overriding their
      -- default behavior. For example, here we set the section for
      -- cursor location to LINE:COLUMN
      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_location = function()
        return '%2l:%-2v'
      end

      -- Remove git branch from statusline
      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_git = function()
        return ''
      end
    end,
  },
  { -- Highlight, edit, and navigate code
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
      -- Autoinstall languages that are not installed
      auto_install = true,
      highlight = {
        enable = true,
      },
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
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
  },
}, {
  ui = {
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },
})

require('oil').setup {
  natural_order = false,
  keymaps = {
    ['<C-s>'] = false, -- Disable the C-s keymap
  },
  sort = {
    { 'ctime', 'desc' },
  },
  view_options = {
    show_hidden = true,
  },
}

local navbuddy = require 'nvim-navbuddy'
local actions = require 'nvim-navbuddy.actions'

navbuddy.setup {
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

vim.keymap.set('n', '<leader>y', '<cmd>Navbuddy<CR>')
-- Create non-existent files when using gf
vim.keymap.set('n', 'gf', function()
  local path = vim.fn.expand '<cfile>'
  if path == '' then
    return
  end

  -- Check if the file exists
  local file_exists = vim.fn.filereadable(path) == 1

  if not file_exists then
    -- Create the directory structure if needed
    local dir = vim.fn.fnamemodify(path, ':h')
    if dir ~= '.' and vim.fn.isdirectory(dir) == 0 then
      vim.fn.mkdir(dir, 'p')
    end

    -- Create the file
    local file = io.open(path, 'w')
    if file then
      file:close()
    end
  end

  -- Open the file (whether it existed before or was just created)
  vim.cmd('edit ' .. vim.fn.fnameescape(path))
end, { noremap = true })

local notify = require 'notify'
notify.setup {
  render = 'minimal',
  timeout = 3000,
  background_colour = 'Normal',
}

-- Emacs-style command line editing
vim.cmd [[
cnoremap <C-a> <Home>
cnoremap <C-e> <End>
cnoremap <C-b> <Left>
cnoremap <C-f> <Right>
cnoremap <C-d> <Del>
cnoremap <C-h> <BS>
cnoremap <C-k> <C-\>e(strpart(getcmdline(), 0, getcmdpos() - 1))<CR>
cnoremap <C-u> <C-\>e""<CR>
]]
