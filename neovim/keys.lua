local opts = { noremap=true, silent=true }
local bufopts = { noremap=true, silent=true, buffer=bufnr }
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
vim.keymap.set('n', '<Leader>a', ReloadConfig, {desc = 'Reload Neovim config'}) -- Reload config (Sort of working)

-- Toggles
map('n', '<Leader>i', '<cmd>setlocal number!<CR>')                              -- Toggle line numbers
map('n', '<Leader>o', '<cmd>set paste!<CR>')                                    -- Toggle paste formatting
map('n', '<Leader>-', '<cmd>nohlsearch<CR>')                                    -- SPACE+- to turn off search highlight
map('n', '<F6>', '<cmd>setlocal spell!<CR>')                                    -- Toggle spellcheck

-- Telescope
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<C-p>', function()                                         -- CTRL+p to open fuzzy file finder
    builtin.find_files({layout_config=calc_telescope_layout()})
  end)
vim.keymap.set('n', '<C-b>', builtin.buffers, {desc='Open fuzzy buffer finder'})-- CTRL+b to open fuzzy buffer finder
vim.keymap.set('n', '<C-g>', builtin.live_grep, {desc = 'Open live grep'})      -- CTRL+g to open folder-wide live grep using Ripgrep
vim.keymap.set('n', '<Leader>t', '<cmd>Telescope<CR>')
vim.keymap.set('n', '<Leader>k', builtin.keymaps, {desc = 'Open keymaps'})

-- Theme
vim.keymap.set('n', '<Leader>d', set_theme_dark, {desc = 'Dark theme'})         -- SPACE+d to set dark background
vim.keymap.set('n', '<Leader>l', set_theme_light, {desc = 'Light theme'})       -- SPACE+l to set light background

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
    print "In quickfix"
    return '\r'
  else
    print 'Not in quickfix'
    return '<cmd>cn<CR>'
  end
end
vim.keymap.set('n', '<CR>', next_quickfix_entry, expropts)                      -- Next quickfix entry (except when in quickfix window)
map('n', '<Leader><CR>', '<cmd>cp<CR>')                                         -- Previous quickfix entry
map('n', '<Leader>q', '<cmd>ccl<CR>')                                           -- Close quickfix window

-- NvimTree
map('n', '<C-f>', '<cmd>NvimTreeToggle<CR>')                                    -- CTRL+f to open NERDTree
map('n', '<Leader>f', '<cmd>NvimTreeFindFile<CR>')                              -- Find and reveal the current file in NERDTree

-- LSP Client
vim.keymap.set('n', '<Leader>e', vim.diagnostic.open_float, {desc = 'Open error popup'})
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, {desc = 'Previous error'})
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, {desc = 'Next error'})
vim.keymap.set('n', '<Leader>g', vim.diagnostic.setqflist, {desc = 'Show errors for project'})

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
function on_attach(client, bufnr)
  -- Used to be for completion but disabled for now
end

function setup_lsp_keys()
  -- Mappings.
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  vim.keymap.set('n', 'gD', vim.lsp.buf.type_definition, bufopts)
  -- vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts) - Doesn't work in F#
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
  vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
  vim.keymap.set('i', '<C-k>', vim.lsp.buf.signature_help, bufopts)
  vim.keymap.set('n', '<Leader>wa', vim.lsp.buf.add_workspace_folder, bufopts)
  vim.keymap.set('n', '<Leader>wr', vim.lsp.buf.remove_workspace_folder, bufopts)
  vim.keymap.set('n', '<Leader>wl', function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, bufopts)
  vim.keymap.set('n', '<Leader>rn', vim.lsp.buf.rename, bufopts)
  vim.keymap.set('n', '<Leader>ca', vim.lsp.buf.code_action, bufopts)
  vim.keymap.set('n', '<Leader>F', function() vim.lsp.buf.format { async = true } end, bufopts)
end

-- F#
map('n', '<Leader>#', '<cmd>call v:lua.create_fsharp_env()<CR>')                -- Setup windows for F# development