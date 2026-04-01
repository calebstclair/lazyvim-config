return {
  {
    "mfussenegger/nvim-dap",
    opts = function()
      local dap = require("dap")

      dap.adapters.ruby = {
        type = "server",
        host = "127.0.0.1",
        port = 1234,
      }

      dap.configurations.ruby = {
        {
          type = "ruby",
          name = "Attach to Docker (rdbg)",
          request = "attach",
          localfs = true,
          command = "attach",
        },
      }
    end,
  },
}
