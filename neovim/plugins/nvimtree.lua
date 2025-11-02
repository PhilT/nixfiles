require("nvim-tree").setup {
  view = {
    width = 40,
  },
  actions = {
    open_file = {
      quit_on_open = true,
      window_picker = {
        enable = false
      }
    }
  },
  live_filter = {
    always_show_folders = false
  },
  on_attach = function(bufnr)
    local api = require('nvim-tree.api')

    -- Default mappings
    api.config.mappings.default_on_attach(bufnr)

    -- Custom mappings for Colemak navigation
    local function opts(desc)
      return { desc = 'nvim-tree: ' .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
    end

    -- Remove default 'e' (rename) and remap to up (mirrors n for down)
    vim.keymap.del('n', 'e', { buffer = bufnr })
    vim.keymap.set('n', 'e', 'k', opts('Up'))
  end
}