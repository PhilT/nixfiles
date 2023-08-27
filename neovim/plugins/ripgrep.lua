-- `Rg <terms>` or `Rg` Search for terms or word under cursor
vim.cmd("command! -nargs=* Rg :cexpr system('rg --smart-case --vimgrep '.('<args>' == '' ? expand('<cword>') : '<args>'))|:bot copen")

