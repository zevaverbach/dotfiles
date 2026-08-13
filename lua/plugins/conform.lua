return {
  'stevearc/conform.nvim',
  lazy = false,
  opts = {
    notify_on_error = false,
    notify_no_formatters = false,
    format_on_save = function(bufnr)
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
      markdown = { 'prettierd', 'prettier' },
    },
  },
}
