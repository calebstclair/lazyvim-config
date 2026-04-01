return {
  {
    "stevearc/overseer.nvim",
    opts = {
      templates = { "docker_rake" },
    },
    keys = {
      { "<leader>ot", "<cmd>OverseerToggle<cr>", desc = "Overseer: toggle" },
      { "<leader>or", "<cmd>OverseerRun<cr>", desc = "Overseer: run task" },
    },
  },
}
