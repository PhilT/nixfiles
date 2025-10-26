local map = vim.keymap.set

-- Setup
map('n', '<C-z>', '<Nop>')                                                      -- Turn off stupid CTRL keys
map('n', '<C-s>', '<Nop>')                                                      -- Turn off stupid CTRL keys
map('n', '<C-q>', '<Nop>')                                                      -- Turn off stupid CTRL keys
map('n', '<Space>', '<Nop>')                                                    -- Unmap spacebar

-- Remap keys that will be used for movement
map('n', 's','i')                                                               -- inSert mode
map('n', 't', 'o')                                                              -- Open a new line below
map('n', 'T', 'O')                                                              -- Open a new line above


-- Movement keys (normal, visual, operator-pending modes)
map('nvo', 'n', 'j')
map('nvo', 'e', 'k')
map('nvo', 'i', 'l')
map('nvo', 'm', 'h')
map('n', '<C-n>', '<C-w>j')                                                     -- CTRL+(neio) to navigate splits from NORMAL mode
map('n', '<C-e>', '<C-w>k')                                                     --
map('n', '<C-i>', '<C-w>l')                                                     --
map('n', '<C-c>', '<C-w>c')                                                     -- 'CTRL+c' to close window

-- Remap displaced Vim functionality
map('nvo', 'k', 'n')                                                            -- Next search result
map('nvo', 'K', 'N')                                                            -- Previous search result
map('nvo', 'l', 'e')                                                            -- End of word
map('nvo', 'L', 'E')                                                            -- End of WORD
map('n', 'S', 'I')                                                              -- Insert at start of line
map('n', 'h', 'm')                                                              -- Set mark
map('nvo', 'z', 'b')                                                            -- Back by word (b remapped for split leader)

-- Split keyboard leaders for ergonomics
-- Left hand: qazwrxfscptdbgv + Enter
-- Right hand: jmklnhue,yi.;o/
local L = 'b'  -- Left-hand leader (for right-side target keys)
local R = 'j'  -- Right-hand leader (for left-side target keys)

-- Neovim
map('n', R..'a', ReloadConfig, {desc = 'Reload Neovim config'})

-- Toggles
map('n', L..'i', '<cmd>setlocal number!<CR>', {desc = 'Toggle line numbers'})
map('n', L..'o', '<cmd>set paste!<CR>', {desc = 'Toggle paste'})
map('n', L..'-', '<cmd>nohlsearch<CR>', {desc = 'Clear search highlight'})

-- FZF Lua
local fzf = require('fzf-lua')
map('n', R..'t', fzf.builtin, {desc = 'Open FZF picker'})
map('n', L..'k', fzf.keymaps, {desc = 'Open keymaps'})

-- Ruby
map('n', R..'r', '<cmd>Dispatch rspec %<CR>', {desc = 'Run RSpec for file'})
map('n', R..'R', '<cmd>Dispatch rspec<CR>', {desc = 'Run RSpec for all'})

-- Theme
map('n', R..'d', set_theme_dark, {desc = 'Dark theme'})
map('n', L..'l', set_theme_light, {desc = 'Light theme'})

-- Quickfix
map('n', R..'<CR>', '<cmd>cp<CR>', {desc = 'Previous quickfix entry'})
map('n', R..'q', '<cmd>ccl<CR>', {desc = 'Close quickfix window'})

-- NvimTree
map('n', R..'f', '<cmd>NvimTreeFindFile<CR>', {desc = 'Find file in tree'})

-- LSP Client
map('n', L..'e', vim.diagnostic.open_float, {desc = 'Open error popup'})
map('n', R..'g', vim.diagnostic.setqflist, {desc = 'Show errors for project'})

-- LSP (from setup_lsp_keys function)
map('n', R..'w'..'a', vim.lsp.buf.add_workspace_folder, {desc = 'Add workspace folder'})
map('n', R..'w'..'r', vim.lsp.buf.remove_workspace_folder, {desc = 'Remove workspace folder'})
map('n', R..'w'..'l', function() print(vim.inspect(vim.lsp.buf.list_workspace_folders())) end, {desc = 'List workspace folders'})
map('n', R..'r'..'n', vim.lsp.buf.rename, {desc = 'LSP rename'})
map('n', R..'c'..'a', vim.lsp.buf.code_action, {desc = 'Code action'})
map('n', R..'F', function() vim.lsp.buf.format { async = true } end, {desc = 'Format buffer'})

-- Rust debugger
map('n', R..'d'..'b', ':lua require"dap".toggle_breakpoint()<CR>', {desc = 'Toggle breakpoint'})
map('n', R..'d'..'c', ':lua require"dap".continue()<CR>', {desc = 'Continue debugging'})
map('n', R..'d'..'i', ':lua require"dap".step_into()<CR>', {desc = 'Step into'})
map('n', R..'d'..'o', ':lua require"dap".step_over()<CR>', {desc = 'Step over'})
map('n', R..'d'..'r', ':lua require"dap".repl.toggle()<CR>', {desc = 'Toggle REPL'})