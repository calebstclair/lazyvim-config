local map = vim.keymap.set

-- FlutterTools commands
map("n", "<leader>rs", "<cmd>FlutterRun<CR>", { desc = "Flutter Run", buffer = true })
map("n", "<leader>rr", "<cmd>FlutterReload<CR>", { desc = "Hot Reload", buffer = true })
map("n", "<leader>rR", "<cmd>FlutterRestart<CR>", { desc = "Hot Restart", buffer = true })
map("n", "<leader>rd", "<cmd>FlutterDevices<CR>", { desc = "Pick Device", buffer = true })
map("n", "<leader>rl", "<cmd>FlutterLogToggle<CR>", { desc = "Toggle Logs", buffer = true })
