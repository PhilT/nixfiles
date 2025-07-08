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
  }
}