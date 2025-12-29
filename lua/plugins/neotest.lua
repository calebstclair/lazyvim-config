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
          rspec_cmd = function(test_args)
            local pid = vim.fn.getpid()
            local project_root = "/Navis"
            local results_file = project_root .. "/tmp/rspec-" .. pid .. ".json"

            -- Detect whether this is a single-test run or multi-test run
            -- A single test is when a test has a line number (file.rb:123)
            local function is_single_test(args)
              if not args then
                return false
              end
              if type(args) == "string" then
                return args:match(":%d+$") ~= nil
              end
              for _, a in ipairs(args) do
                if type(a) == "string" and a:match(":%d+$") then
                  return true
                end
              end
              return false
            end

            local use_parallel = not is_single_test(test_args)

            local cmd = {
              "docker",
              "compose",
              "exec",
              "-e",
              "RAILS_ENV=test",
              "web",
              "bundle",
              "exec",
            }

            if use_parallel then
              -- parallel_tests invocation
              vim.list_extend(cmd, {
                "parallel_rspec",
                "--serialize-stdout",
                "--combine-stderr",
                "--", -- End parallel_rspec args, begin rspec args
              })
            else
              -- normal rspec for single examples
              vim.list_extend(cmd, { "rspec" })
            end

            -- RSpec formatters for Neotest
            vim.list_extend(cmd, {
              "--format",
              "progress",
              "--format",
              "json",
              "--out",
              results_file,
            })

            if not test_args then
              test_args = {}
            elseif type(test_args) == "string" then
              test_args = { test_args }
            end

            -- If running an entire directory
            if test_args[1] == "dir" then
              table.insert(cmd, project_root .. "/spec")
            else
              -- Normalize test paths
              for _, arg in ipairs(test_args) do
                if arg == "file" or arg == "namespace" then
                  arg = vim.api.nvim_buf_get_name(0)
                end

                local abs = vim.fn.fnamemodify(arg, ":p")
                if vim.fn.filereadable(abs) == 0 and vim.fn.isdirectory(abs) == 0 then
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

          -- Host path so Neotest can read results
          results_path = function()
            return vim.fn.getcwd() .. "/tmp/rspec-" .. vim.fn.getpid() .. ".json"
          end,

          formatter = "json",
        },
      },
    },
  },
}
