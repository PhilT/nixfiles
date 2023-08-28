local cmd = vim.cmd

-- No need to set it as it's sourced
-- cmd.colorscheme('greyscale')

function set_theme_dark()
  vim.opt.background = 'dark'
end

function set_theme_light()
  vim.opt.background = 'light'
end

set_theme_dark()

