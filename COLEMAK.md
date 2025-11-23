## Movement & Window Nav

- `m` `n` `e` `i` → left/down/up/right
- `s` → insert mode (instead of `i`)
- `CTRL+m` `CTRL+n` `CTRL+e` `CTRL+i` → navigate splits
- `CTRL+c` → close window

## Displaced Vim Functions

- `k`/`K` → next/previous search     `l`/`L` → end of word/WORD
- `S` → insert at start of line      `h` → set mark
- `z` → back by word                 `b<SPACE>` → Winresizer

## Leader Keys

- `b`/`j` = Left & right leader (for right & left target keys)

### Neovim
- `ja` → reload Neovim config

### Toggles
- `bi` → toggle line numbers
- `bo` → toggle paste
- `b'` → clear search highlight

### FZF
- `jt` → open FZF picker
- `bk` → open keymaps

### Ruby
- `jr` → RSpec (current file)        `jR` → RSpec (all files)

### Theme
- `jd`/`bl` → dark/light theme

### Quickfix
- `j<CR>` → previous quickfix entry
- `jq` → close quickfix window

### LSP
- `be` → open error popup            `jg` → show errors for project
- `jwa` → add workspace folder       `jwr` → remove workspace folder
- `jwl` → list workspace folders     `jrn` → LSP rename
- `jca` → code action                `jF` → format buffer

### Debugger
- `jdb` → toggle breakpoint          `jdc` → continue debugging
- `jdi` → step into                  `jdo` → step over
- `jdr` → toggle REPL