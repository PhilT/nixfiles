local cmd = vim.cmd

cmd.colorscheme('catppuccin-macchiato')

function set_theme_dark()
  vim.opt.background = 'dark'
end

function set_theme_light()
  vim.opt.background = 'light'
end

--set_theme_dark()