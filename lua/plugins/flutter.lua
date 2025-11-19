return {
  {
    "akinsho/flutter-tools.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = true, -- Auto-configures the plugin
  },
  { "dart-lang/dart-vim-plugin" }, -- Syntax highlighting and other Dart-specific features
  -- You might also want to add nvim-treesitter for enhanced syntax parsing
  -- { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
}
