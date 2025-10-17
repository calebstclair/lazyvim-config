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
      adapters = {
        ["neotest-rspec"] = {
          -- Command to run RSpec inside Docker
          rspec_cmd = function(test_args)
            local pid = vim.fn.getpid()
            local results_file = "/Navis/tmp/rspec-" .. pid .. ".json"

            local cmd = {
              "docker",
              "compose",
              "exec",
              "-T",
              "-e",
              "RAILS_ENV=test",
              "web",
              "bundle",
              "exec",
              "rspec",
              "--out",
              results_file,
            }

            -- Append test files/lines if provided
            if test_args then
              if type(test_args) == "string" then
                test_args = { test_args }
              end
              for _, arg in ipairs(test_args) do
                -- Convert host absolute path to container path
                local cwd = vim.fn.getcwd()
                local relative = arg:gsub("^" .. vim.pesc(cwd), "")
                if string.sub(relative, 1, 1) == "/" then
                  relative = string.sub(relative, 2)
                end
                table.insert(cmd, "/Navis/" .. relative)
              end
            end

            return cmd
          end,

          -- Transform host paths to container relative paths
          transform_spec_path = function(path)
            local cwd = vim.fn.getcwd()
            local relative = path:gsub("^" .. vim.pesc(cwd), "")
            if string.sub(relative, 1, 1) == "/" then
              relative = string.sub(relative, 2)
            end
            return relative
          end,

          -- JSON results file path
          results_path = function()
            return "/Navis/tmp/rspec-" .. vim.fn.getpid() .. ".json"
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
