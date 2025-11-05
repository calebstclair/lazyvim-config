return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-treesitter/nvim-treesitter",
      "olimorris/neotest-rspec",
    },
    opts = {
      consumers = {
        overseer = require("neotest.consumers.overseer"),
      },
      adapters = {
        ["neotest-rspec"] = {
          rspec_cmd = function(test_args)
            local pid = vim.fn.getpid()
            local project_root = "/Navis"
            local results_file = project_root .. "/tmp/rspec-" .. pid .. ".json"

            local cmd = {
              "docker",
              "compose",
              "exec",
              "-e",
              "RAILS_ENV=test",
              "web",
              "bundle",
              "exec",
              "rspec",
              "--format",
              "progress",
              "--format",
              "json",
              "--out",
              results_file,
            }

            if test_args then
              if type(test_args) == "string" then
                test_args = { test_args }
              end
              for _, arg in ipairs(test_args) do
                if arg == "namespace" or arg == "file" then
                  arg = vim.api.nvim_buf_get_name(0)
                end

                local abs = vim.fn.fnamemodify(arg, ":p")

                if not vim.fn.filereadable(abs) then
                  abs = vim.api.nvim_buf_get_name(0)
                end

                local cwd = vim.fn.getcwd()
                local relative = abs:gsub("^" .. vim.pesc(cwd) .. "/", "")
                table.insert(cmd, project_root .. "/" .. relative)
              end
            end

            print("🐳 Neotest RSpec CMD:\n" .. table.concat(cmd, " "))
            return cmd
          end,

          transform_spec_path = function(path)
            local cwd = vim.fn.getcwd()
            local relative = path:gsub("^" .. vim.pesc(cwd) .. "/", "")
            return relative
          end,

          -- Host path (for Neotest to read)
          results_path = function()
            return vim.fn.getcwd() .. "/tmp/rspec-" .. vim.fn.getpid() .. ".json"
          end,

          formatter = "json",
        },
      },

      -- UI features
      status = { enabled = true, virtual_text = true, signs = true },
      output = { enabled = true, open_on_run = "short" },
      output_panel = { enabled = true, open = "botright split | resize 15" },
      quickfix = { enabled = true, open = false },
      running = { concurrent = false },
      diagnostic = { enabled = true, severity = vim.diagnostic.severity.ERROR },
    },
  },
}
