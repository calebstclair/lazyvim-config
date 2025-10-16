return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-treesitter/nvim-treesitter",
      -- Use a fork that better supports Docker
      { "olimorris/neotest-rspec", branch = "main" },
    },
    keys = {
      {
        "<leader>tw",
        function()
          require("neotest").watch.toggle(vim.fn.expand("%"))
        end,
        desc = "Toggle Watch File",
      },
    },
    opts = function()
      return {
        -- Enable status signs and virtual text for real-time feedback
        status = {
          enabled = true,
          signs = true,
          virtual_text = false,
        },

        -- Enable diagnostics for inline error messages
        diagnostic = {
          enabled = true,
          severity = vim.diagnostic.severity.ERROR,
        },

        -- Output configuration - show short output automatically
        output = {
          enabled = true,
          open_on_run = "short",
        },

        -- Output panel for full stdout/stderr
        output_panel = {
          enabled = true,
          open = "botright split | resize 15",
        },

        -- Summary window configuration
        summary = {
          enabled = true,
          animated = true,
          follow = true,
          expand_errors = true,
          open = "botright vsplit | vertical resize 50",
          mappings = {
            attach = "a",
            clear_marked = "M",
            clear_target = "T",
            debug = "d",
            debug_marked = "D",
            expand = { "<CR>", "<2-LeftMouse>" },
            expand_all = "e",
            help = "?",
            jumpto = "i",
            mark = "m",
            next_failed = "J",
            output = "o",
            prev_failed = "K",
            run = "r",
            run_marked = "R",
            short = "O",
            stop = "u",
            target = "t",
            watch = "w",
          },
        },

        -- Enable concurrent test running for real-time updates
        running = {
          concurrent = true,
        },

        -- Discovery settings
        discovery = {
          enabled = true,
          concurrent = 0,
        },

        -- Custom icons for visual feedback
        icons = {
          passed = "P",
          failed = "F",
          running = "R",
          skipped = "S",
          unknown = "U",
        },

        -- Adapter configuration
        adapters = {
          require("neotest-rspec")({
            -- Docker Compose integration - build the command ourselves
            rspec_cmd = function(position_type)
              return {
                "docker-compose",
                "exec",
                "-T",
                "web",
                "bundle",
                "exec",
                "rspec",
                "--format",
                "json",
                "--out",
                "/tmp/rspec-neotest.json",
              }
            end,

            transform_spec_path = function(path)
              local cwd = vim.fn.getcwd()

              local relative_path = path:gsub("^" .. vim.pesc(cwd) .. "/", "")

              return relative_path
            end,

            results_path = function()
              return vim.fn.getcwd() .. "/tmp/rspec.output"
            end,
          }),
        },
      }
    end,
    config = function(_, opts)
      local neotest = require("neotest")
      neotest.setup(opts)

      -- Auto-open summary when running tests
      local summary_open = false

      -- Store original run function
      local original_run = neotest.run.run

      -- Wrap run function to open summary
      neotest.run.run = function(args)
        if not summary_open then
          vim.schedule(function()
            neotest.summary.open()
            summary_open = true
          end)
        end
        return original_run(args)
      end

      -- Track summary window state
      vim.api.nvim_create_autocmd("WinClosed", {
        pattern = "*",
        callback = function()
          summary_open = false
        end,
      })

      vim.api.nvim_create_autocmd("BufWinLeave", {
        pattern = "*",
        callback = function(ev)
          local bufname = vim.api.nvim_buf_get_name(ev.buf)
          if bufname:match("Neotest Summary") then
            summary_open = false
          end
        end,
      })
    end,
  },
}
