require("catppuccin").setup({
  -- M get's chopped off with Atkinson Hyperlegible font and I like non-italic comments better
  no_italic = true,
})

function set_theme_dark()
  vim.opt.background = 'dark'
  vim.cmd.colorscheme('catppuccin-mocha')
end

function set_theme_light()
  vim.opt.background = 'light'
  vim.cmd.colorscheme('catppuccin-latte')
end

set_theme_dark()