-- Neovim Configuration Entry Point
-- This file is loaded from /data/code/nixfiles/neovim/ for instant config changes

-- Disable netrw (must be first, before any plugins load)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Emergency escape hatch: backslash-semicolon to get command mode
-- Works on both QWERTY and Colemak layouts
vim.keymap.set('n', '\\;', ':', { noremap = true })

-- Reload configuration function
function ReloadConfig()
  for name,_ in pairs(package.loaded) do
    package.loaded[name] = nil
  end
  dofile(vim.env.MYVIMRC)
  vim.notify("Nvim configuration reloaded!", vim.log.levels.INFO)
end

-- Base configuration path
local config_path = '/data/code/nixfiles/neovim'

-- Load core configuration files
dofile(config_path .. '/opts.lua')
dofile(config_path .. '/theme.lua')
dofile(config_path .. '/keys.lua')
dofile(config_path .. '/autocmds.lua')

-- Load plugin configurations
dofile(config_path .. '/plugins/ai.lua')
dofile(config_path .. '/plugins/dap.lua')
dofile(config_path .. '/plugins/fugitive.lua')
dofile(config_path .. '/plugins/lualine.lua')
dofile(config_path .. '/plugins/nvimtree.lua')
dofile(config_path .. '/plugins/purescript.lua')
dofile(config_path .. '/plugins/ripgrep.lua')
dofile(config_path .. '/plugins/scratch.lua')
dofile(config_path .. '/plugins/fzf.lua')
dofile(config_path .. '/plugins/toggleterm.lua')
dofile(config_path .. '/plugins/treesitter.lua')
dofile(config_path .. '/plugins/lsp.lua')

-- Conditional Colemak layout loading
-- Enable via: NVIM_COLEMAK=1 nvim
-- Or: touch ~/.config/nvim/use-colemak
local function load_colemak()
  dofile(config_path .. '/colemak.lua')
  vim.notify("Colemak layout loaded", vim.log.levels.INFO)
  _G.colemak_enabled = true
end

if os.getenv('NVIM_COLEMAK') == '1' or
   vim.fn.filereadable(vim.fn.expand('~/.config/nvim/use-colemak')) == 1 then
  load_colemak()
else
  _G.colemak_enabled = false
end

-- Runtime toggle command
vim.api.nvim_create_user_command('ColemakToggle', function()
  if _G.colemak_enabled then
    -- Reload config to disable Colemak
    ReloadConfig()
  else
    -- Load Colemak layout
    load_colemak()
  end
end, { desc = 'Toggle Colemak keyboard layout' })
