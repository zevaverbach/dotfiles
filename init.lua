local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end

vim.opt.rtp:prepend(lazypath)
vim.opt.colorcolumn = "120"
vim.opt.updatetime = 50 -- improve perf, less frequent swp writes
vim.opt.termguicolors = true
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.smartindent = true
vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

require("lazy").setup({
    "github/copilot.vim",
    "folke/tokyonight.nvim",
    "tpope/vim-commentary",
    {
        "folke/trouble.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        opts = {
        },
    },
    {
        'nvim-telescope/telescope.nvim', tag = '0.1.5',
        dependencies = { 'nvim-lua/plenary.nvim',
    'BurntSushi/ripgrep'}
    },
    {'nvim-telescope/telescope-fzf-native.nvim', build = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build'},
    {'VonHeikemen/lsp-zero.nvim', branch = 'v3.x'},
    {'neovim/nvim-lspconfig'},
    {'hrsh7th/cmp-nvim-lsp'},
    {'hrsh7th/nvim-cmp'},
    {"mfussenegger/nvim-jdtls"},
    {'L3MON4D3/LuaSnip'},
    {"neoclide/coc.nvim", branch = 'release'},
    {
        "kylechui/nvim-surround",
        version = "*",
        event = "VeryLazy",
        config = function()
            require("nvim-surround").setup({
            })
        end
    },
})
require('telescope').setup {
    extensions = {
        fzf = {
            fuzzy = true,                    -- false will only do exact matching
            override_generic_sorter = true,  -- override the generic sorter
            override_file_sorter = true,     -- override the file sorter
            case_mode = "smart_case",        -- or "ignore_case" or "respect_case"
            -- the default case_mode is "smart_case"
        }
    }
}
local vimrc = vim.fn.stdpath("config") .. "/vimrc.vim"
vim.cmd.source(vimrc)
local lsp_zero = require('lsp-zero')

lsp_zero.on_attach(function(client, bufnr)
    lsp_zero.default_keymaps({buffer = bufnr})
end)
require('lspconfig').pyright.setup({
virtual_text=false,
})

local config = {
    cmd = {
        --
        "/usr/bin/java", -- Or the absolute path '/path/to/java11_or_newer/bin/java'
        "-Declipse.application=org.eclipse.jdt.ls.core.id1",
        "-Dosgi.bundles.defaultStartLevel=4",
        "-Declipse.product=org.eclipse.jdt.ls.core.product",
        "-Dlog.protocol=true",
        "-Dlog.level=ALL",
        "-Xms1g",
        "--add-modules=ALL-SYSTEM",
        "--add-opens",
        "java.base/java.util=ALL-UNNAMED",
        "--add-opens",
        "java.base/java.lang=ALL-UNNAMED",
        --
        "-jar",
        "/usr/local/Cellar/jdtls/1.32.0/libexec/plugins/org.eclipse.equinox.launcher_1.6.700.v20231214-2017.jar",
        "-configuration", "/usr/local/Cellar/jdtls/1.32.0/libexec/config_mac",
        "-data", "/Users/zev/.local/share/nvim/java"
    },
    settings = {
        java = {
            signatureHelp = {enabled = true},
            import = {enabled = true},
            rename = {enabled = true}
        }
    },
    init_options = {
        bundles = {}
    }
}

