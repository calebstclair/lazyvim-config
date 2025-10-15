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
    keys = {
      -- Only define keys that LazyVim doesn't already provide
      -- LazyVim already has <leader>tt, <leader>tT, <leader>tr, <leader>tl, <leader>ts, <leader>to, <leader>tO
      {
        "<leader>tw",
        function()
          require("neotest").watch.toggle(vim.fn.expand("%"))
        end,
        desc = "Toggle Watch File",
      },
    },
    opts = {
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

      -- Custom icons for visual feedback
      icons = {
        passed = "✓",
        failed = "✗",
        running = "●",
        skipped = "○",
        unknown = "?",
        running_animated = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
      },

      -- Adapter configuration
      adapters = {
        ["neotest-rspec"] = {
          -- Docker Compose integration
          rspec_cmd = function()
            return {
              "docker-compose",
              "exec",
              "-T", -- Disable pseudo-TTY allocation
              "web", -- Change this to your service name
              "bundle",
              "exec",
              "rspec",
            }
          end,

          -- Transform spec path to work inside container
          transform_spec_path = function(path)
            local cwd = vim.fn.getcwd()
            local container_path = "/Navis" -- Your container working directory

            -- Try to auto-detect from docker-compose.yml
            local compose_file = cwd .. "/docker-compose.yml"
            if vim.fn.filereadable(compose_file) == 1 then
              local handle = io.open(compose_file, "r")
              if handle then
                local content = handle:read("*a")
                handle:close()

                -- Look for working_dir (remove quotes and whitespace)
                local working_dir = content:match("working_dir:%s*['\"]?([^'\"\\s\n]+)")
                if working_dir then
                  container_path = working_dir
                end

                -- Look for volume mapping like ".:/Navis"
                if not working_dir then
                  local volume = content:match("%./?:([^:\\s\n]+)")
                  if volume then
                    container_path = volume
                  end
                end
              end
            end

            -- Make path relative to project root, then prepend container path
            local relative_path = path:gsub("^" .. vim.pesc(cwd), "")
            local transformed = container_path .. relative_path

            return transformed
          end,

          -- Results path transformation if needed
          results_path = function()
            return vim.fn.getcwd() .. "/tmp/rspec.output"
          end,
        },
      },
    },
    config = function(_, opts)
      local neotest = require("neotest")
      neotest.setup(opts)

      -- Auto-open summary when running tests
      local summary_open = false

      -- Store original run function
      local original_run = neotest.run.run

      -- Wrap run function to open summary
      neotest.run.run = function(args)
        -- Open summary if not already open
        if not summary_open then
          vim.schedule(function()
            neotest.summary.open()
            summary_open = true
          end)
        end

        -- Call original run function
        return original_run(args)
      end

      -- Track summary window state
      vim.api.nvim_create_autocmd("WinClosed", {
        pattern = "*",
        callback = function()
          -- Simple approach: try to close and catch if already closed
          summary_open = false
        end,
      })

      -- Also track when summary is explicitly closed
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
