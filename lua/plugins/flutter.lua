return {
  -- Keep LazyVim's dart LSP
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        dartls = {},
      },
    },
  },

  -- Add flutter-tools only
  {
    "akinsho/flutter-tools.nvim",
    lazy = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "stevearc/dressing.nvim",
    },
    config = function()
      require("flutter-tools").setup({
        lsp = {
          on_attach = function(client, bufnr)
            -- use LazyVim defaults
          end,
        },
      })
    end,
  },
}
