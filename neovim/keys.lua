local map = vim.keymap.set
local opts = { noremap=true, silent=true }
local expropts = { noremap=true, silent=true, expr=true }

-- Setup
map('n', '<C-z>', '<Nop>')                                                      -- Turn off stupid CTRL keys
map('n', '<C-s>', '<Nop>')                                                      -- Turn off stupid CTRL keys
map('n', '<C-q>', '<Nop>')                                                      -- Turn off stupid CTRL keys
map('n', '<Space>', '<Nop>')                                                    -- Unmap spacebar
vim.g.mapleader = ' '                                                           -- Make spacebar the leader key
vim.g.localleader = ' '

-- Movement keys
map('t', '<A-e>', '<C-\\><C-n>')                                                -- ALT+e switches to NORMAL mode from TERMINAL mode
map('t', '<A-h>', '<C-\\><C-n><C-w>h')                                          --
map('t', '<A-j>', '<C-\\><C-n><C-w>j')                                          -- ALT+(hjkl) to navigate splits from terminal mode...
map('t', '<A-k>', '<C-\\><C-n><C-w>k')                                          --
map('t', '<A-l>', '<C-\\><C-n><C-w>l')                                          --
map('i', '<A-h>', '<C-\\><C-n><C-w>h')                                          -- ...insert mode
map('i', '<A-j>', '<C-\\><C-n><C-w>j')                                          --
map('i', '<A-k>', '<C-\\><C-n><C-w>k')                                          --
map('i', '<A-l>', '<C-\\><C-n><C-w>l')                                          --
map('n', '<A-h>', '<C-w>h')                                                     -- ...normal mode
map('n', '<A-j>', '<C-w>j')                                                     --
map('n', '<A-k>', '<C-w>k')                                                     --
map('n', '<A-l>', '<C-w>l')                                                     --
map('n', '<C-h>', '<C-w>h')                                                     -- CTRL+(hjkl) to navigate splits from NORMAL mode
map('n', '<C-j>', '<C-w>j')                                                     --
map('n', '<C-k>', '<C-w>k')                                                     --
map('n', '<C-l>', '<C-w>l')                                                     --
map('n', '<C-c>', '<C-w>c')                                                     -- 'CTRL+c' to close window

-- Neovim
map('n', '<Leader>a', ReloadConfig, {desc = 'Reload Neovim config'}) -- Reload config (Sort of working)

-- Toggles
map('n', '<Leader>i', '<cmd>setlocal number!<CR>')                              -- Toggle line numbers
map('n', '<Leader>o', '<cmd>set paste!<CR>')                                    -- Toggle paste formatting
map('n', '<Leader>-', '<cmd>nohlsearch<CR>')                                    -- SPACE+- to turn off search highlight
map('n', '<F6>', '<cmd>setlocal spell!<CR>')                                    -- Toggle spellcheck

-- FZF Lua
-- See plugins/fzf.lua for keymaps once FZF is open
local fzf = require('fzf-lua')
map('n', '<C-p>', fzf.files, {desc = 'Open fuzzy file finder'})      -- CTRL+p to open fuzzy file finder
map('n', '<C-b>', fzf.buffers, {desc='Open fuzzy buffer finder'})    -- CTRL+b to open fuzzy buffer finder
map('n', '<C-g>', fzf.live_grep, {desc = 'Open live grep'})          -- CTRL+g to open folder-wide live grep using Ripgrep
map('n', '<Leader>t', fzf.builtin, {desc = 'Open FZF picker'})
map('n', '<Leader>k', fzf.keymaps, {desc = 'Open keymaps'})

-- Ruby
map('n', '<Leader>r', '<cmd>Dispatch rspec %<CR>')                              -- Run RSpec for given file
map('n', '<Leader>R', '<cmd>Dispatch rspec<CR>')                                -- Run RSpec for everything

-- Theme
map('n', '<Leader>d', set_theme_dark, {desc = 'Dark theme'})         -- SPACE+d to set dark background
map('n', '<Leader>l', set_theme_light, {desc = 'Light theme'})       -- SPACE+l to set light background

-- Session
map('n', '<C-x>', '<cmd>wa<CR><cmd>mksession!<CR><cmd>qa<CR>')                  -- CTRL+x to save all buffers, save session and exit vim

-- Scratch
map('n', 'go', '<cmd>ScratchFile<CR>')                                          -- go to switch to Scratch window for making notes

-- Windows
map('n', 'zz', '<c-w>_ \\| <c-w>\\|')                                           -- Zoom in and maximize current window
map('n', 'zo', '<c-w>=')                                                        -- Zoom out and equalize windows
map('n', 'tt', '<cmd>sp<CR><cmd>term<CR>')                                      -- Open terminal in new tab

-- Tabs
map('n', 'ta', '<cmd>tabe<CR>')                                                 -- Add tab pane
map('n', 'tc', '<cmd>tabc<CR>')                                                 -- Clear (remove) tab pane

-- Quickfix
local next_quickfix_entry = function()
  if vim.bo.buftype == 'quickfix' then
    return '\r'
  else
    return '<cmd>cn<CR>'
  end
end
map('n', '<CR>', next_quickfix_entry, expropts)                      -- Next quickfix entry (except when in quickfix window)
map('n', '<Leader><CR>', '<cmd>cp<CR>')                                         -- Previous quickfix entry
map('n', '<Leader>q', '<cmd>ccl<CR>')                                           -- Close quickfix window

-- NvimTree
map('n', '<C-f>', '<cmd>NvimTreeToggle<CR>')                                    -- CTRL+f to open NvimTree
map('n', '<Leader>f', '<cmd>NvimTreeFindFile<CR>')                              -- Find and reveal the current file in NvimTree

-- LSP Client
map('n', '<Leader>e', vim.diagnostic.open_float, {desc = 'Open error popup'})
map('n', '[d', vim.diagnostic.goto_prev, {desc = 'Previous error'})
map('n', ']d', vim.diagnostic.goto_next, {desc = 'Next error'})
map('n', '<Leader>g', vim.diagnostic.setqflist, {desc = 'Show errors for project'})

local tab_completion = function()
  local _, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()

  if vim.fn.pumvisible() == 0 then
    local char = string.sub(line, col, col)
    if col == 0 or char == ' ' then
      return '<tab>'
    else
      return '<c-x><c-o>'
    end
  else
    return '<c-n>'
  end
end

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
function on_attach(client, bufnr)
  -- Enable completion triggered by <c-x><c-o> and map it to TAB
  vim.bo[bufnr].omnifunc = 'v:lua.vim.lsp.omnifunc'
end

function setup_lsp_keys()
  map('i', '<tab>', tab_completion, expropts)

  -- Mappings.
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  map('n', 'gD', vim.lsp.buf.type_definition)
  -- map('n', 'gD', vim.lsp.buf.declaration) - Doesn't work in F#
  map('n', 'gd', vim.lsp.buf.definition)
  map('n', 'gr', vim.lsp.buf.references)
  map('n', 'K', vim.lsp.buf.hover)
  map('n', 'gi', vim.lsp.buf.implementation)
  map('i', '<C-k>', vim.lsp.buf.signature_help)
  map('n', '<Leader>wa', vim.lsp.buf.add_workspace_folder)
  map('n', '<Leader>wr', vim.lsp.buf.remove_workspace_folder)
  map('n', '<Leader>wl', function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end)
  map('n', '<Leader>rn', vim.lsp.buf.rename)
  map('n', '<Leader>ca', vim.lsp.buf.code_action)
  map('n', '<Leader>F', function() vim.lsp.buf.format { async = true } end)
end

-- F#
map('n', '<Leader>#', '<cmd>call v:lua.create_fsharp_env()<CR>')                -- Setup windows for F# development

-- Rust debugger
map('n', '<leader>db', ':lua require"dap".toggle_breakpoint()<CR>')
map('n', '<leader>dc', ':lua require"dap".continue()<CR>')
map('n', '<leader>di', ':lua require"dap".step_into()<CR>')
map('n', '<leader>do', ':lua require"dap".step_over()<CR>')
map('n', '<leader>dr', ':lua require"dap".repl.toggle()<CR>')