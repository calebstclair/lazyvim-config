local function ensure_web_running()
  local h = io.popen("docker compose ps -q web 2>/dev/null")
  local out = h and h:read("*a") or ""
  if h then
    h:close()
  end

  if out == "" then
    vim.notify("Starting docker compose service: web…", vim.log.levels.INFO)
    os.execute("docker compose up -d web >/dev/null 2>&1")
    vim.uv.sleep(1500)
  end
end

return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "olimorris/neotest-rspec",
    },

    opts = function()
      return {
        adapters = {
          require("neotest-rspec")({
            ---------------------------------------------------
            -- Run all RSpec inside docker compose exec web
            ---------------------------------------------------
            rspec_cmd = function()
              ensure_web_running()

              return {
                "docker",
                "compose",
                "exec",
                "-T",
                "web",
                "bundle",
                "exec",
                "rspec",
                "--format",
                "documentation",
                "--format",
                "json",
                "--out",
                "tmp/rspec.output",
              }
            end,

            ---------------------------------------------------
            -- Fix file paths so rspec sees valid paths
            ---------------------------------------------------
            transform_spec_path = function(path)
              local root = require("neotest-rspec").root(path)
              return root and path:sub(#root + 2) or path
            end,

            results_path = "tmp/rspec.output",
          }),
        },
      }
    end,

    -----------------------------------------------------------
    -- Keymaps (only additions—LazyVim already sets neotest defaults)
    -----------------------------------------------------------
    keys = {
      -------------------------------------------------------------------
      -- Parallel RSpec
      -- <leader>tP => parallel_rspec inside docker, results fed to neotest
      -------------------------------------------------------------------
      {
        "<leader>tP",
        function()
          ensure_web_running()

          vim.notify("Running parallel_rspec inside docker…", vim.log.levels.INFO)

          -- Open a terminal pane
          vim.cmd("botright split | resize 15")
          local buf = vim.api.nvim_create_buf(false, true)
          vim.api.nvim_win_set_buf(0, buf)

          -- Run parallel tests
          vim.fn.termopen(
            [[docker compose exec -T web bash -c "
              rm -f tmp/parallel_rspec.json &&
              parallel_rspec spec/
            "]],
            {
              on_exit = function(_, code)
                vim.schedule(function()
                  if code == 0 then
                    vim.notify("Parallel tests passed ✓", vim.log.levels.INFO)
                  else
                    vim.notify("Parallel tests failed ✗", vim.log.levels.ERROR)
                  end

                  os.execute("docker compose exec -T web cp tmp/parallel_rspec.json tmp/rspec.output")
                  require("neotest").summary.open()
                end)
              end,
            }
          )
        end,
        desc = "Run parallel_rspec in docker",
      },
    },

    -----------------------------------------------------------
    -- Apply configuration
    -----------------------------------------------------------
    config = function(_, opts)
      require("neotest").setup(opts)
    end,
  },
}
