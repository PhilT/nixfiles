-- Tree-sitter configuration for syntax highlighting
require('nvim-treesitter.configs').setup({
  -- Enable syntax highlighting
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },

  -- Enable indentation
  indent = {
    enable = true,
  },
})
