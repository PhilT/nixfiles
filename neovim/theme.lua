local cmd = vim.cmd

--Need to make it a plugin
--cmd.colorscheme('greyscale')

function set_theme_dark()
  vim.opt.background = 'dark'
end

function set_theme_light()
  vim.opt.background = 'light'
end

set_theme_dark()

