vim.api.nvim_create_user_command('ScratchFile', function()
  local cwd = vim.fn.getcwd()                                                   -- Get the current working directory
  local scratch_path = cwd .. "/.scratch.txt"                                   -- Set the scratch file path
  vim.cmd("topleft split " .. scratch_path)                                     -- Open the scratch file in a new split
  vim.cmd("resize 15")                                                          -- Resize the scratch file to 15 lines
end, {})