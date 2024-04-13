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
	"folke/tokyonight.nvim",
	"tpope/vim-commentary",
	{
		"folke/trouble.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = {},
	},
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.5",
		dependencies = { "nvim-lua/plenary.nvim", "BurntSushi/ripgrep" },
	},
	{
		"nvim-telescope/telescope-fzf-native.nvim",
		build = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build",
	},
	{ "VonHeikemen/lsp-zero.nvim", branch = "v3.x" },
	{ "neovim/nvim-lspconfig" },
	{ "nvim-treesitter/nvim-treesitter" },
	{
		"stevearc/conform.nvim",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			require("conform").setup({
				formatters_by_ft = {
					lua = { "stylua" },
					svelte = { { "prettierd", "prettier" } },
					javascript = { { "prettierd", "prettier" } },
					typescript = { { "prettierd", "prettier" } },
					javascriptreact = { { "prettierd", "prettier" } },
					typescriptreact = { { "prettierd", "prettier" } },
					json = { { "prettierd", "prettier" } },
					graphql = { { "prettierd", "prettier" } },
					java = { "google-java-format" },
					kotlin = { "ktlint" },
					ruby = { "standardrb" },
					markdown = { { "prettierd", "prettier" } },
					erb = { "htmlbeautifier" },
					html = { "htmlbeautifier" },
					bash = { "beautysh" },
					proto = { "buf" },
					rust = { "rustfmt" },
					yaml = { "yamlfix" },
					toml = { "taplo" },
					css = { { "prettierd", "prettier" } },
					scss = { { "prettierd", "prettier" } },
				},
				format_on_save = {
					-- These options will be passed to conform.format()
					timeout_ms = 500,
					lsp_fallback = true,
				},
			})
		end,
	},
	{
		"mfussenegger/nvim-lint",
		event = {
			"BufReadPre",
			"BufNewFile",
		},
		config = function()
			local lint = require("lint")
			lint.linters_by_ft = {
				javascript = { "eslint_d" },
				typescript = { "eslint_d" },
				javascriptreact = { "eslint_d" },
				typescriptreact = { "eslint_d" },
				svelte = { "eslint_d" },
				kotlin = { "ktlint" },
				terraform = { "tflint" },
				ruby = { "standardrb" },
			}
			local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
			vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
				group = lint_augroup,
				callback = function()
					lint.try_lint()
				end,
			})
		end,
	},
	{ "hrsh7th/nvim-cmp" },
	{ "hrsh7th/cmp-nvim-lsp" },
	{ "hrsh7th/cmp-buffer" },
	{ "hrsh7th/vim-vsnip" },
	{ "L3MON4D3/LuaSnip" },
	{ "czheo/mojo.vim" },
	{ "neoclide/coc.nvim", branch = "release" },
	{
		"kylechui/nvim-surround",
		version = "*",
		event = "VeryLazy",
		config = function()
			require("nvim-surround").setup({})
		end,
	},
})
require("telescope").setup({
	extensions = {
		fzf = {
			fuzzy = true, -- false will only do exact matching
			override_generic_sorter = true, -- override the generic sorter
			override_file_sorter = true, -- override the file sorter
			case_mode = "smart_case", -- or "ignore_case" or "respect_case"
			-- the default case_mode is "smart_case"
		},
	},
})
local vimrc = vim.fn.stdpath("config") .. "/vimrc.vim"
vim.cmd.source(vimrc)

local cmp = require("cmp")
cmp.setup({
	snippet = {
		expand = function(args)
			vim.fn["vsnip#anonymous"](args.body)
		end,
	},

	mapping = {
		["C-y"] = cmp.mapping.confirm({ select = true }),
	},

	sources = {
		{ name = "nvim_lsp" },
		{ name = "buffer" },
	},
})

local lsp_zero = require("lsp-zero")

lsp_zero.on_attach(function(client, bufnr)
	lsp_zero.default_keymaps({ buffer = bufnr })
end)

lspconfig = require("lspconfig")

lspconfig.pyright.setup({
	virtual_text = false,
})

local capabilities = require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities())

lspconfig.clangd.setup({
	capabilities = capabilities,
})

local configs = require("lspconfig.configs")
if not configs.jinja_lsp then
	configs.jinja_lsp = {
		default_config = {
			cmd = { "/Users/zev/.cargo/bin/jinja-lsp" },
			filetypes = { "jinja", "rs" },
			root_dir = function(fname)
				return lspconfig.util.find_git_ancestor(fname)
			end,
			settings = {
				templates = "./templates",
				backend = { "./app" },
				lang = "rust",
			},
		},
	}
end

lspconfig.jinja_lsp.setup({})
vim.api.nvim_create_augroup("AutoFormat", {})

vim.api.nvim_create_autocmd("BufWritePost", {
	pattern = "*.py",
	group = "AutoFormat",
	callback = function()
		vim.cmd("silent !black --line-length=120 --quiet %")
		vim.cmd("edit")
	end,
})

local function on_list(options)
	vim.fn.setqflist({}, " ", options)
	vim.api.nvim_command("cfirst")
end

local bufopts = { noremap = true, silent = true, buffer = bufnr }
vim.keymap.set("n", "<leader>d", function()
	vim.lsp.buf.definition({ on_list = on_list })
end, bufopts)
vim.keymap.set("n", "<leader>r", function()
	vim.lsp.buf.references(nil, { on_list = on_list })
end, bufopts)
