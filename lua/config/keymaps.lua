-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("v", ">", ">gv", { desc = "Indent and stay in visual mode" })
vim.keymap.set("v", "<", "<gv", { desc = "Outdent and stay in visual mode" })

vim.keymap.set("n", "<leader>yc", function()
  local diag = vim.diagnostic.get(0, { lnum = vim.fn.line(".") - 1 })[1]
  if diag then
    vim.fn.setreg("+", diag.message)
    vim.notify("Copied diagnostic: " .. diag.message)
  else
    vim.notify("No diagnostic on this line")
  end
end, { desc = "Copy diagnostic under cursor" })
