local map = vim.keymap.set

map("n", "<leader>R", "<cmd>Cargo run<CR>", { desc = "Cargo Run", buffer = true })
map("n", "<leader>rt", "<cmd>Cargo test<CR>", { desc = "Cargo Test", buffer = true })
map("n", "<leader>rb", "<cmd>Cargo build<CR>", { desc = "Cargo Build", buffer = true })
map("n", "<leader>rr", "<cmd>RustReloadWorkspace<CR>", { desc = "Reload Workspace", buffer = true })

-- Optional: Rust tools plugin
map("n", "<leader>rd", "<cmd>RustDebuggables<CR>", { desc = "Rust Debuggables", buffer = true })
