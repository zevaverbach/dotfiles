-- Auto-reload files changed externally (WYSIWYG editors, git, etc.)
vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter', 'CursorHold', 'CursorHoldI' }, {
  pattern = '*',
  command = 'checktime',
})

-- Quickfix window: open to the right at 30% screen width
local function resize_quickfix()
  for _, win in pairs(vim.fn.getwininfo()) do
    if win.quickfix == 1 then
      local qf_width = math.floor(vim.o.columns * 0.3)
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
    vim.cmd 'wincmd L'
    resize_quickfix()
  end,
})

vim.api.nvim_create_autocmd('VimResized', {
  callback = resize_quickfix,
})

-- Restore last cursor position on buffer read
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

-- Persist manual folds across sessions
local persist_folds_group = vim.api.nvim_create_augroup('PersistFolds', { clear = true })
local function should_persist_view()
  if vim.bo.buftype ~= '' then
    return false
  end
  if vim.bo.filetype == 'gitcommit' or vim.bo.filetype == 'gitrebase' then
    return false
  end
  return vim.api.nvim_buf_get_name(0) ~= ''
end

vim.api.nvim_create_autocmd('BufWinLeave', {
  group = persist_folds_group,
  callback = function()
    if should_persist_view() then
      pcall(vim.cmd, 'mkview')
    end
  end,
})

vim.api.nvim_create_autocmd('BufWinEnter', {
  group = persist_folds_group,
  callback = function()
    if should_persist_view() then
      pcall(vim.cmd, 'loadview')
    end
  end,
})

-- Golang: hard tabs, width 4
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'go',
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.expandtab = false
  end,
})

-- C/C++: 4-space indent (overrides the built-in C ftplugin which uses hard tabs).
-- clang-format's UseTab setting determines what survives a save.
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'c', 'cpp' },
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.expandtab = true
  end,
})

-- SQL files: indent with 3 spaces.
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('SqlIndent', { clear = true }),
  pattern = 'sql',
  callback = function()
    vim.bo.expandtab = true
    vim.bo.shiftwidth = 3
    vim.bo.tabstop = 3
    vim.bo.softtabstop = 3
  end,
})

-- Highlight yanked text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- C/C++: warn once per project if no compile database is present.
-- clangd needs compile_commands.json (or compile_flags.txt) to resolve includes.
local cc_checked = {}
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'c', 'cpp' },
  callback = function(args)
    local fname = vim.api.nvim_buf_get_name(args.buf)
    if fname == '' then
      return
    end
    local found = vim.fs.find({ 'compile_commands.json', 'compile_flags.txt' }, {
      path = vim.fs.dirname(fname),
      upward = true,
    })[1]
    if found then
      return
    end
    local root = vim.fs.root(args.buf, { '.git' }) or vim.fs.dirname(fname)
    if cc_checked[root] then
      return
    end
    cc_checked[root] = true
    vim.notify(
      'clangd: no compile_commands.json under ' .. root .. '\n' .. 'To generate:\n' .. '  CMake:  cmake -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=1\n' .. '  Make:   bear -- make    (brew install bear)\n' .. '  Manual: echo "<flags>" > compile_flags.txt',
      vim.log.levels.WARN,
      { title = 'clangd' }
    )
  end,
})

-- Format Fennel files on save
local function fnlfmt()
  local filename = vim.fn.expand '%:p'
  local result = vim.fn.system('fnlfmt --fix ' .. vim.fn.shellescape(filename))
  if vim.v.shell_error ~= 0 then
    vim.notify('fnlfmt failed: ' .. result, vim.log.levels.ERROR)
    return
  end
  vim.cmd 'edit'
end

vim.api.nvim_create_augroup('FennelOnSave', { clear = true })
vim.api.nvim_create_autocmd('BufWritePost', {
  group = 'FennelOnSave',
  pattern = '*.fnl',
  callback = fnlfmt,
})
