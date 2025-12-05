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

local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- ============================
-- Black-hole deletes (default)
-- ============================

-- Normal-mode delete operations → black hole
map("n", "d", '"_d', opts)
map("n", "D", '"_D', opts)
map("n", "x", '"_x', opts)
map("n", "X", '"_X', opts)
map("n", "c", '"_c', opts)
map("n", "C", '"_C', opts)

-- Visual-mode delete/change → black hole
map("v", "d", '"_d', opts)
map("v", "c", '"_c', opts)
map("v", "x", '"_x', opts)

-- ============================
-- System clipboard cut with 'y' prefix
-- ============================

-- Normal-mode cuts
map("n", "yd", '"+d', opts)
map("n", "yD", '"+D', opts)
map("n", "yx", '"+x', opts)
map("n", "yX", '"+X', opts)
map("n", "yc", '"+c', opts)
map("n", "yC", '"+C', opts)

-- Visual-mode cuts
map("v", "yd", '"+d', opts)
map("v", "yx", '"+x', opts)
map("v", "yc", '"+c', opts)
