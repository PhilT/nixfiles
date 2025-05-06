-- lua vim.lsp.set_log_level("debug")
-- lua print(vim.lsp.get_log_path())

-- use on_attach key binds from keys.lua
require'lspconfig'.clangd.setup{on_attach = on_attach}                          -- C/C++
require'lspconfig'.csharp_ls.setup{on_attach = on_attach}                       -- C#
require'lspconfig'.fsautocomplete.setup{on_attach = on_attach}                  -- F#
require'lspconfig'.gdscript.setup{on_attach = on_attach}                        -- GD Script (Godot)
require'lspconfig'.ruby_lsp.setup{on_attach = on_attach, cmd = {'devbox', 'run', '--', 'ruby-lsp'}} -- Ruby
require'lspconfig'.rust_analyzer.setup{on_attach = on_attach}                   -- Rust
require'lspconfig'.terraformls.setup{}

setup_lsp_keys()

-- Terraform
vim.api.nvim_create_autocmd({"BufWritePre"}, {
  pattern = {"*.tf", "*.tfvars"},
  callback = function()
    vim.lsp.buf.format()
  end,
})
