require("claudecode").setup({
  terminal = {
    provider = "external",
    provider_opts = {
      external_terminal_cmd = "kitty -- %s",
    },
  },
})

local map = vim.keymap.set

map('n', '<Leader>C', '<cmd>ClaudeCode<CR>', { desc = 'Toggle Claude Code' })
map('v', '<Leader>C', '<cmd>ClaudeCodeSend<CR>', { desc = 'Send selection to Claude' })
map('n', '<Leader>cb', '<cmd>ClaudeCodeAdd %<CR>', { desc = 'Add buffer to Claude' })
