-- Tree-sitter configuration for syntax highlighting
-- nvim-treesitter's `main` branch (NixOS 26.05+) dropped the old
-- `require('nvim-treesitter.configs').setup{}` API. Highlighting is now
-- provided by Neovim natively via `vim.treesitter.start()`, and indentation
-- via the plugin's `indentexpr()`. Grammars come from `withAllGrammars`.

local ts_group = vim.api.nvim_create_augroup('treesitter_config', { clear = true })

-- Enable syntax highlighting for any filetype that has a parser installed.
-- pcall so filetypes without a grammar don't raise on start.
vim.api.nvim_create_autocmd('FileType', {
  group = ts_group,
  callback = function()
    pcall(vim.treesitter.start)
  end,
})

-- Enable tree-sitter indentation, except for Rust (indent had bugs there).
vim.api.nvim_create_autocmd('FileType', {
  group = ts_group,
  callback = function(args)
    if vim.bo[args.buf].filetype == 'rust' then
      return
    end
    vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})
