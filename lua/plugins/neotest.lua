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
    opts = function()
      -- Helper function to check and start Docker container
      local function ensure_container_running()
        local handle = io.popen("docker compose ps -q web 2>/dev/null")
        if not handle then
          return false
        end

        local result = handle:read("*a") or ""
        handle:close()

        if result == "" then
          vim.notify("Starting Docker container 'web'...", vim.log.levels.INFO)
          os.execute("docker compose up -d web 2>/dev/null")
          vim.uv.sleep(2000)
        end
        return true
      end

      return {
        adapters = {
          require("neotest-rspec")({
            -- Use our Docker wrapper script instead of calling rspec directly
            rspec_cmd = function()
              ensure_container_running()
              return vim.tbl_flatten({
                vim.fn.getcwd() .. "/bin/docker-rspec",
              })
            end,

            -- Transform the spec path to be relative for Docker
            transform_spec_path = function(path)
              local root = require("neotest-rspec").root(path)
              if not root then
                return path
              end
              return string.sub(path, string.len(root) + 2, -1)
            end,

            -- Use consistent results path
            results_path = "tmp/rspec.output",

            -- Use our custom streaming formatter
            formatter = "StreamingJsonFormatter",

            -- Don't filter any directories except node_modules
            filter_dir = function(name, rel_path, root)
              return name ~= "node_modules"
            end,
          }),
        },

        -- Status display configuration
        status = {
          enabled = true,
          virtual_text = true,
          signs = true,
        },

        -- Output configuration
        output = {
          enabled = true,
          open_on_run = true,
        },

        -- Disable quickfix
        quickfix = {
          enabled = false,
        },

        -- Summary window configuration
        summary = {
          enabled = true,
          animated = true,
          follow = true,
          expand_errors = true,
        },

        -- Enable icons with animation
        icons = {
          running_animated = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
        },

        -- Output panel settings
        output_panel = {
          enabled = true,
          open = "botright split | resize 15",
        },

        -- Discovery settings
        discovery = {
          enabled = true,
        },

        -- Run settings
        run = {
          enabled = true,
        },
      }
    end,

    keys = {
      -- Standard LazyVim neotest keymaps
      {
        "<leader>tt",
        function()
          require("neotest").run.run(vim.fn.expand("%"))
        end,
        desc = "Run File",
      },
      {
        "<leader>tT",
        function()
          -- Run all tests sequentially (NOT parallel)
          require("neotest").run.run(vim.uv.cwd())
        end,
        desc = "Run All Test Files",
      },
      {
        "<leader>tr",
        function()
          require("neotest").run.run()
        end,
        desc = "Run Nearest",
      },
      {
        "<leader>tl",
        function()
          require("neotest").run.run_last()
        end,
        desc = "Run Last",
      },
      {
        "<leader>ts",
        function()
          require("neotest").summary.toggle()
        end,
        desc = "Toggle Summary",
      },
      {
        "<leader>to",
        function()
          require("neotest").output.open({ enter = true, auto_close = true })
        end,
        desc = "Show Output",
      },
      {
        "<leader>tO",
        function()
          require("neotest").output_panel.toggle()
        end,
        desc = "Toggle Output Panel",
      },
      {
        "<leader>tS",
        function()
          require("neotest").run.stop()
        end,
        desc = "Stop",
      },
      {
        "<leader>tw",
        function()
          require("neotest").watch.toggle(vim.fn.expand("%"))
        end,
        desc = "Toggle Watch",
      },

      -- PARALLEL TESTS: Custom implementation that actually works
      {
        "<leader>tP",
        function()
          -- Check if web container is running
          local handle = io.popen("docker compose ps -q web 2>/dev/null")
          if not handle then
            vim.notify("Failed to check Docker status", vim.log.levels.ERROR)
            return
          end

          local result = handle:read("*a") or ""
          handle:close()

          -- Start container if not running
          if result == "" then
            vim.notify("Starting Docker container 'web'...", vim.log.levels.INFO)
            os.execute("docker compose up -d web 2>/dev/null")
            vim.uv.sleep(2000)
          end

          vim.notify("Running tests in parallel...", vim.log.levels.INFO)

          -- Open neotest summary to show results
          require("neotest").summary.open()

          -- Run parallel_rspec in background and parse results
          local Job = require("plenary.job")

          Job
            :new({
              command = "docker",
              args = {
                "compose",
                "exec",
                "-T",
                "web",
                "bash",
                "-c",
                -- Use SPEC_OPTS to pass formatter options to avoid conflicts with parallel_rspec's -f flag
                "SPEC_OPTS='--require ./spec/support/streaming_json_formatter.rb --format StreamingJsonFormatter --out /Navis/tmp/rspec_parallel.output' parallel_rspec spec/",
              },
              on_stdout = function(_, data)
                print(data)
              end,
              on_stderr = function(_, data)
                print(data)
              end,
              on_exit = function(j, return_val)
                vim.schedule(function()
                  if return_val == 0 then
                    vim.notify("Parallel tests passed!", vim.log.levels.INFO)
                  else
                    vim.notify("Parallel tests failed!", vim.log.levels.ERROR)
                  end

                  -- Parse the results file and update neotest
                  local results_file = vim.fn.getcwd() .. "/tmp/rspec_parallel.output"
                  if vim.fn.filereadable(results_file) == 1 then
                    -- Trigger neotest to refresh - it will pick up the new results
                    require("neotest").run.run(vim.uv.cwd())
                  end
                end)
              end,
            })
            :start()
        end,
        desc = "Run All Tests (Parallel)",
      },
    },

    config = function(_, opts)
      -- Setup neotest with options
      require("neotest").setup(opts)

      -- Additional configuration for better streaming
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "neotest-output",
        callback = function()
          vim.opt_local.number = false
          vim.opt_local.relativenumber = false
          vim.opt_local.wrap = false
        end,
      })

      -- Auto-open summary when running tests
      vim.api.nvim_create_autocmd("User", {
        pattern = "NeotestRunStarted",
        callback = function()
          require("neotest").summary.open()
        end,
      })

      -- Set up file watcher for progressive updates from streaming formatter
      -- This polls the results file and triggers UI updates as tests complete
      local watching = {}
      vim.api.nvim_create_autocmd("User", {
        pattern = "NeotestRunStarted",
        callback = function(args)
          local results_path = vim.fn.getcwd() .. "/tmp/rspec.output"

          if not watching[results_path] then
            watching[results_path] = true

            -- Clear the file before starting
            local file = io.open(results_path, "w")
            if file then
              file:write("")
              file:close()
            end

            -- Create a timer to poll the results file
            local timer = vim.loop.new_timer()
            local last_size = 0

            if timer then
              timer:start(
                0,
                300,
                vim.schedule_wrap(function()
                  -- Check if file exists and has grown
                  local stat = vim.loop.fs_stat(results_path)
                  if stat and stat.size > last_size then
                    last_size = stat.size
                    -- File has new content, trigger a redraw
                    vim.cmd("redraw")
                  end
                end)
              )

              -- Stop timer after tests complete
              vim.api.nvim_create_autocmd("User", {
                pattern = "NeotestRunFinished",
                once = true,
                callback = function()
                  if timer then
                    timer:stop()
                    timer:close()
                  end
                  watching[results_path] = nil
                end,
              })
            end
          end
        end,
      })
    end,
  },
}
