vim.api.nvim_create_user_command('ScratchFile', function()
  local cwd = vim.fn.getcwd()                                                   -- Get the current working directory
  local path_match = string.match(cwd, "^(/[^/]+/[^/]+)")                       -- Extract first two path segments (e.g. /data/work)
  local base_path = path_match or cwd                                           -- Fallback: if not matched, use whole cwd
  local scratch_path = base_path .. "/scratch.md"                               -- Compose the scratch file path
  vim.cmd("topleft split " .. scratch_path)
  vim.cmd("resize 15")
end, {})