-- Configure render-markdown.nvim to hide code block language labels
require('render-markdown').setup({
  code = {
    style = 'normal', -- Use 'normal' instead of 'full' to hide language name/icon above code blocks
  },
})
