require("supermaven-nvim").setup({
  keymaps = {
    accept_suggestion = "<S-Tab>",
    clear_suggestion = "<C-]>",
    accept_word = "<C-l>",
  }
})

-- Add Colemak equivalent for accept_word
vim.keymap.set('i', '<C-i>', function()
  require('supermaven-nvim.completion_preview').on_accept_suggestion_word()
end, { desc = 'Supermaven accept word (Colemak)' })