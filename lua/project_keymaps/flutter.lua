local map = function(mode, keys, cmd, desc)
  vim.keymap.set(mode, keys, cmd, { desc = desc })
end

-- Use <leader>R as your project command prefix
map("n", "<leader>Rr", ":FlutterRun<CR>", "Flutter Run")
map("n", "<leader>Rh", ":FlutterHotReload<CR>", "Hot Reload")
map("n", "<leader>RR", ":FlutterHotRestart<CR>", "Hot Restart")
map("n", "<leader>Rbi", ":FlutterBuild ipa<CR>", "Build iOS")
map("n", "<leader>Rbm", ":FlutterBuild macos<CR>", "Build macOS")
map("n", "<leader>Rd", ":DartFmt<CR>", "Format Dart")

print("[Project Keymaps] Loaded Flutter keymaps")
