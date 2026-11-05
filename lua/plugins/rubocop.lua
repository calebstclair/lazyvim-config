-- Run the project's rubocop (with its plugins) when the Gemfile.lock has it, otherwise the global one.
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        rubocop = {
          cmd = function(dispatchers, config)
            local root = config.root_dir or vim.fn.getcwd()
            local lockfile = root .. "/Gemfile.lock"
            local bundled = vim.fn.filereadable(lockfile) == 1
              and vim.iter(vim.fn.readfile(lockfile)):any(function(line)
                return line:match("^    rubocop %(") ~= nil
              end)
            local cmd = bundled and { "bundle", "exec", "rubocop", "--lsp" } or { "rubocop", "--lsp" }
            return vim.lsp.rpc.start(cmd, dispatchers, { cwd = root })
          end,
        },
      },
    },
  },
}
