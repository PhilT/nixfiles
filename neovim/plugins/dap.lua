local dap = require('dap')

dap.adapters.lldb = {
  type = 'executable',
  command = '/run/current-system/sw/bin/lldb-dap',
  name = 'lldb'
}

dap.configurations.rust = {
  {
    name = "Launch file",
    type = "lldb",
    request = "launch",
    program = function()
      return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/target/debug/', 'file')
    end,
    cwd = '${workspaceFolder}',
    stopOnEntry = false,
  },
}