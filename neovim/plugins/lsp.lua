-- lua vim.lsp.set_log_level("debug")
-- lua print(vim.lsp.get_log_path())

-- Add borders to diagnostic floating windows
vim.diagnostic.config({
  float = { border = 'rounded' }
})

-- Set default borders and disable concealment for LSP floating windows
local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
  opts = opts or {}
  opts.border = opts.border or 'rounded'
  local bufnr, winnr = orig_util_open_floating_preview(contents, syntax, opts, ...)
  return bufnr, winnr
end

-- use on_attach key binds from keys.lua
vim.lsp.config('clangd', {on_attach = on_attach})                          -- C/C++
vim.lsp.enable('clangd')

vim.lsp.config('csharp_ls', {on_attach = on_attach})                       -- C#
vim.lsp.enable('csharp_ls')

vim.lsp.config('fsautocomplete', {on_attach = on_attach})                  -- F#
vim.lsp.enable('fsautocomplete')

vim.lsp.config('gdscript', {on_attach = on_attach})                        -- GD Script (Godot)
vim.lsp.enable('gdscript')

vim.lsp.config('ruby_lsp', {                                               -- Ruby
  on_attach = on_attach,
  cmd = {'bundle', 'exec', 'ruby-lsp'},
  root_dir = function(bufnr, on_dir)
    local fname = vim.api.nvim_buf_get_name(bufnr)
    -- Find all Gemfiles going upward, use the outermost one
    -- This allows a parent wrapper Gemfile to be the root for monorepos
    local gemfiles = vim.fs.find('Gemfile', {
      path = vim.fs.dirname(fname),
      upward = true,
      limit = math.huge,
    })
    local gemfile = gemfiles[#gemfiles]  -- Last one is the outermost
    if gemfile then
      on_dir(vim.fs.dirname(gemfile))
    end
  end,
})
vim.lsp.enable('ruby_lsp')

vim.lsp.enable('terraformls')

vim.lsp.enable('glsl_analyzer')

setup_lsp_keys()

-- Terraform
vim.api.nvim_create_autocmd({"BufWritePre"}, {
  pattern = {"*.tf", "*.tfvars"},
  callback = function()
    vim.lsp.buf.format()
  end,
})

require'claudecode'.setup()