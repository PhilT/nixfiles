local is_windows = vim.fn.has('win32') == 1
local group = vim.api.nvim_create_augroup('mygroup', { clear = true })
local autocmd = vim.api.nvim_create_autocmd
--TODO: Probably remove this once I've decided how I'll get stuff done from now on.
--local todo_path = file_exist('TODO.md') and 'TODO.md' or os.getenv('NOTES')..'/todo.txt'      -- Set TODO file to local project if it exists otherwise main todo.txt in D:\txt

function _G.term_run(command)                                                   -- Run a build command e.g. 'run', 'test', 'build'
  autocmd('TermEnter', {                                                        -- When entering insert mode in terminal switch back out of it
    command = 'TermOpen * call v:lua.switch_out_of_term()',
    group = group
  })
  vim.cmd('term '..command)
end

function _G.create_fsharp_env()                                                 -- Prepare Neovim for developing F# project
  setup_lsp_client()
  init_build_mappings()

  if #vim.api.nvim_tabpage_list_wins(0) == 1 then                               -- Only create splits if there aren't any (E.g. Hasn't had a session reloaded)
    vim.cmd('vsplit')                                                           -- Create 3 vertical panes with the last one
    vim.cmd('vsplit')                                                           -- containing a test watcher and the todo list
    if is_windows then
      vim.cmd('term watch.cmd')
    else
      vim.cmd('term ./watch.cmd')
    end
    vim.cmd('wincmd G')
    vim.cmd('split '..todo_path)
    vim.cmd('wincmd h')
  else                                                                          -- Reload any buffers to ensure LSP is working
    vim.cmd('windo e')
    vim.cmd('wincmd 1w')                                                        -- Return to the first split
  end
  print('F# environment loaded')
end

function _G.setup_lsp_client()
  -- TODO: Move LSPs into separate lua script
  require'lspconfig'.rust_analyzer.setup{on_attach = on_attach}
  require'lspconfig'.gdscript.setup{on_attach = on_attach}
  require'lspconfig'.csharp_ls.setup{on_attach = on_attach}
  require'lspconfig'.fsautocomplete.setup{on_attach = on_attach}                -- Load F# LSP using FsAutoComplete and use on_attach key binds from keys.lua
  setup_lsp_keys()

  -- lua vim.lsp.set_log_level("debug")
  -- lua print(vim.lsp.get_log_path())
end

local run_command = function(command)
  local separator = '/'
  if is_windows then separator = '\\' end
  local basePath = "."..separator..command

  local path = vim.api.nvim_buf_get_name(0)
  local cmd = 'bench '..path
  if not path:match('.fsx$') then cmd = basePath..[[.cmd]] end
  if not is_windows and file_exist(command..[[.sh]]) then
    cmd = basePath..[[.sh]]
  end
  vim.cmd([[Dispatch ]]..cmd)
end

--These might need to move into keys.lua
function _G.init_build_mappings()                                               -- Setup dotnet build mappings
  vim.keymap.set('n', '<Leader>m', function() run_command('build') end)         -- dotnet build (Make)
  vim.keymap.set('n', '<Leader>x', function() run_command('clean') end)         -- dotnet clean (eXpunge)
  vim.keymap.set('n', '<Leader>r', function() run_command('run') end)           -- dotnet run
  vim.keymap.set('n', '<Leader>t', function() run_command('test') end)          -- dotnet test unit
  vim.keymap.set('n', '<Leader>T', function() run_command('test') end)          -- dotnet test unit
  vim.keymap.set('n', '<Leader>v', function() run_command('visual') end)        -- dotnet test visual
end

if file_contains('build.cmd', '^dotnet') then                                   -- If a file exists called build.cmd and at least one line starts with dotnet
  setup_lsp_client()                                                            --   then startup the F# environment
  init_build_mappings()

  print('F# environment loaded')
end