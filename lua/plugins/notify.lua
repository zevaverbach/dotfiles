return {
  'rcarriga/nvim-notify',
  lazy = false,
  priority = 900,
  config = function()
    local notify = require 'notify'
    notify.setup {
      render = 'minimal',
      timeout = 3000,
      background_colour = 'Normal',
    }
    -- config.options installs a filtering wrapper on vim.notify and forwards to
    -- `notify_impl`; point it at nvim-notify now that the plugin is loaded.
    require('config.options').notify_impl = notify
  end,
}
