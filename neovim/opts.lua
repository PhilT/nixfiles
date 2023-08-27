local opt = vim.opt
local indent = 2

opt.switchbuf = 'useopen,uselast'                                               -- `:sbuf filepattern` switch to buffer and use available window if visible
opt.cmdheight = 2                                                               -- Doesn't halt nvim for 2 line messages
opt.completeopt = 'menuone,noinsert,noselect'                                   -- popup on 1 item, don't auto-insert selection, don't auto-select a match

opt.expandtab = true                                                            -- Use spaces instead of tabs
opt.shiftwidth = indent                                                         -- Size of an indent
opt.smartindent = true                                                          -- Insert indents automatically
opt.softtabstop = indent                                                        -- Default tab size for when there is no .editorconfig
opt.tabstop = indent                                                            -- Default tab size for when there is no .editorconfig
opt.fileformat = 'unix'                                                         -- Ensure lf line-endings are used on Windows
opt.swapfile = false                                                            -- Don't create temporary swap files

opt.autowrite = true                                                            -- Autosave files before running make
opt.backup = false                                                              -- Don't create backups
opt.fileformats = 'unix,dos'                                                    -- Recognise unix or dos line-endings, save new files as unix
opt.hidden = true                                                               -- hide buffers instead of closing
opt.ignorecase = true                                                           -- See smartcase
opt.incsearch = true                                                            -- Show matches as you type a search
opt.laststatus = 2                                                              -- Always show the statusline
opt.path = vim.o.path..'**'                                                     -- recursively search files
opt.scrolloff = 2                                                               -- Page up/down with 2 extra lines showing above/below cursor position
opt.shortmess = vim.o.shortmess..'c'                                            -- Don't show extra completion status messages
opt.showmode = false                                                            -- Turn off -- INSERT -- in statusline (lightline already shows it)
opt.smartcase = true                                                            -- Case insensitive search when characters in pattern are lowercase
opt.splitbelow = true                                                           -- Open new horizontal splits below the current one
opt.splitright = true                                                           -- Open new vertical splits to the right of the current one
opt.termguicolors = true                                                        -- True color support
opt.updatetime = 100                                                            -- Bring down delay for diagnostic messages
opt.wildignore = vim.o.wildignore..'.git/**,tmp/**,coverage/**,log/**,db/migrate/**,node_modules/**,bin/**,**/*.min.js'
opt.wildmenu = true                                                             -- TAB completion in COMMAND mode
opt.writebackup = false                                                         -- Don't create backups

opt.conceallevel = 2                                                            -- Make Markdown look pretty (hides some characters unless at the cursor)
opt.cursorline = true                                                           -- Turn on highlight on cursor line (Uses color of CursorLine)
opt.foldenable = false                                                          -- Turn off code folding
opt.number = false                                                              -- Hide line numbers
--opt.signcolumn = 'yes'                                                          -- Keeps sign column visable to stop edit window shifting left and right

