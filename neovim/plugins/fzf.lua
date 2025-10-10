require('fzf-lua').setup({
  winopts = {
    height = 0.85,
    width = 0.80,
    row = 0.35,
    col = 0.50,
    border = 'rounded',
    preview = {
      layout = 'horizontal',
      horizontal = 'right:50%',
    },
  },
  keymap = {
    builtin = {
      ['<C-j>'] = 'down',
      ['<C-k>'] = 'up',
    },
    fzf = {
      ['ctrl-j'] = 'down',
      ['ctrl-k'] = 'up',
    },
  },
  files = {
    prompt = 'Files> ',
    cmd = 'rg --files --hidden --ignore-file=/etc/ignore',
  },
  grep = {
    prompt = 'Grep> ',
    cmd = 'rg --column --line-number --no-heading --color=always --smart-case --hidden --ignore-file=/etc/ignore',
  },
})
