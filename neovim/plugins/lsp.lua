-- lua vim.lsp.set_log_level("debug")
-- lua print(vim.lsp.get_log_path())

-- use on_attach key binds from keys.lua
vim.lsp.config('clangd', {on_attach = on_attach})                          -- C/C++
vim.lsp.enable('clangd')

vim.lsp.config('csharp_ls', {on_attach = on_attach})                       -- C#
vim.lsp.enable('csharp_ls')

vim.lsp.config('fsautocomplete', {on_attach = on_attach})                  -- F#
vim.lsp.enable('fsautocomplete')

vim.lsp.config('gdscript', {on_attach = on_attach})                        -- GD Script (Godot)
vim.lsp.enable('gdscript')

vim.lsp.config('ruby_lsp', {                                               -- Ruby
  on_attach = on_attach,
  cmd = {'devbox', 'run', 'ruby-lsp'}
})
vim.lsp.enable('ruby_lsp')

vim.lsp.enable('terraformls')

vim.lsp.enable('glsl_analyzer')

setup_lsp_keys()

-- Terraform
vim.api.nvim_create_autocmd({"BufWritePre"}, {
  pattern = {"*.tf", "*.tfvars"},
  callback = function()
    vim.lsp.buf.format()
  end,
})

require'claudecode'.setup()