local map = vim.keymap.set

-- Disable vim-dispatch default mappings (conflicts with Colemak 'm' mapping)
vim.g.dispatch_no_maps = 1

-- Use alternate winresizer mappings (conflicts with CTRL+e window movement)
vim.g.winresizer_start_key = '<Leader>m'

-- Remap keys that will be used for movement
map('n', 's','i')                                                               -- inSert mode

-- Movement keys (normal, visual modes only - exclude operator-pending to preserve text objects)
map({'n', 'v'}, 'n', 'j')
map({'n', 'v'}, 'e', 'k')
map({'n', 'v'}, 'i', 'l')
map({'n', 'v'}, 'm', 'h')
map('n', '<A-m>', '<C-w>h')                                                     -- ALT+(mnei) to navigate splits from NORMAL mode
map('n', '<A-n>', '<C-w>j')                                                     --
map('n', '<A-e>', '<C-w>k')                                                     --
map('n', '<A-i>', '<C-w>l')                                                     --
map('n', '<C-c>', '<C-w>c')                                                     -- 'CTRL+c' to close window

-- Remap displaced Vim functionality
map({'n', 'v', 'o'}, 'k', 'n')                                                  -- Next search result
map({'n', 'v', 'o'}, 'K', 'N')                                                  -- Previous search result
map({'n', 'v', 'o'}, 'l', 'e')                                                  -- End of word
map({'n', 'v', 'o'}, 'L', 'E')                                                  -- End of WORD
map('n', 'S', 'I')                                                              -- Insert at start of line
map('n', 'h', 'm')                                                              -- Set mark
