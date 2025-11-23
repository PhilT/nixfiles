# Colemak Key Mappings

This document describes the key differences when Colemak mode is enabled in Neovim.

## Movement Keys

- `m` `n` `e` `i` → left/down/up/right (instead of `h` `j` `k` `l`)
- `s` → insert mode (instead of `i`)

## Window Navigation

- `CTRL+m` `CTRL+n` `CTRL+e` `CTRL+i` → navigate splits (instead of `CTRL+h` `CTRL+j` `CTRL+k` `CTRL+l`)
- `CTRL+c` → close window

## Displaced Vim Functions

- `k`/`K` → next/previous search (was `n`/`N`)
- `l`/`L` → end of word/WORD (was `e`/`E`)
- `S` → insert at start of line (was `I`)
- `h` → set mark (was `m`)
- `z` → back by word (was `b`)

## Leader Keys

Uses split leaders for better ergonomics:
- `b` = Left-hand leader (for right-side target keys)
- `j` = Right-hand leader (for left-side target keys)

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
- `jr` → run RSpec for current file
- `jR` → run RSpec for all

### Theme
- `jd` → dark theme
- `bl` → light theme

### Quickfix
- `j<CR>` → previous quickfix entry
- `jq` → close quickfix window

### NvimTree
- `jf` → find file in tree

### LSP
- `be` → open error popup
- `jg` → show errors for project
- `jwa` → add workspace folder
- `jwr` → remove workspace folder
- `jwl` → list workspace folders
- `jrn` → LSP rename
- `jca` → code action
- `jF` → format buffer

### Debugger
- `jdb` → toggle breakpoint
- `jdc` → continue debugging
- `jdi` → step into
- `jdo` → step over
- `jdr` → toggle REPL

## Additional Changes

- Winresizer uses `SPACE+wr` instead of default `CTRL+e`
