return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    filesystem = {
      filtered_items = {
        hide_gitignored = false,
        hide_dotfiles = false, -- optional
        hide_by_name = {}, -- optional
      },
    },
  },
}
