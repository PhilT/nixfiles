## Movement & Window Nav

- `m` `n` `e` `i` → left/down/up/right
- `s` → insert mode (instead of `i`)
- `ALT+m` `ALT+n` `ALT+e` `ALT+i` → navigate splits
- `CTRL+c` → close window

## Displaced Vim Functions

- `k`/`K` → next/previous search     `l`/`L` → end of word/WORD
- `S` → insert at start of line      `h` → set mark
- `<Leader>m` → Winresizer
- `gh` → LSP hover (replaces `K` to preserve prev search)

## Leader Key

- `<Space>` = Leader key (same as standard Vim config)
- All leader-based keybindings are defined in `keys.lua` and work with
  Colemak movement keys