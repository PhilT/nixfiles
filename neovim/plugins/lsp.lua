-- lua vim.lsp.set_log_level("debug")
-- lua print(vim.lsp.get_log_path())

-- use on_attach key binds from keys.lua
require'lspconfig'.clangd.setup{on_attach = on_attach}                          -- C/C++
require'lspconfig'.csharp_ls.setup{on_attach = on_attach}                       -- C#
require'lspconfig'.fsautocomplete.setup{on_attach = on_attach}                  -- F#
require'lspconfig'.gdscript.setup{on_attach = on_attach}                        -- GD Script (Godot)
require'lspconfig'.solargraph.setup{on_attach = on_attach}                      -- Ruby
require'lspconfig'.rust_analyzer.setup{on_attach = on_attach}                   -- Rust

setup_lsp_keys()