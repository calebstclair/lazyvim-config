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

-- Make deletes not affect yank register
local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Normal-mode delete operations → black hole
map("n", "d", '"_d', opts)
map("n", "D", '"_D', opts)
map("n", "x", '"_x', opts)
map("n", "X", '"_X', opts)

-- Change operations (optional — include if you want these too)
map("n", "c", '"_c', opts)
map("n", "C", '"_C', opts)

-- Insert/Visual mode variants
map("v", "d", '"_d', opts)
map("v", "c", '"_c', opts)
map("v", "x", '"_x', opts)
