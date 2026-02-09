-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua

local map = vim.keymap.set

-- =============================================================================
-- Navigation
-- =============================================================================

-- Move through wrapped lines naturally
map({ "n", "x" }, "j", "gj", { desc = "Move down (wrapped)" })
map({ "n", "x" }, "k", "gk", { desc = "Move up (wrapped)" })

-- =============================================================================
-- Buffer Navigation
-- =============================================================================

map("n", "<Left>", "<cmd>bprev<cr>", { desc = "Previous buffer" })
map("n", "<Right>", "<cmd>bnext<cr>", { desc = "Next buffer" })

-- =============================================================================
-- Editing
-- =============================================================================

-- Clear search highlighting
map("n", "<BS>", "<cmd>nohl<cr>", { desc = "Clear search highlight" })

-- Quick save
map({ "n", "i" }, "<Esc><Esc>", "<cmd>w<cr><esc>", { desc = "Save file" })

-- Stay in visual mode when indenting
map("v", "<", "<gv", { desc = "Indent left" })
map("v", ">", ">gv", { desc = "Indent right" })

-- Move lines up/down
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move line down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move line up" })

-- =============================================================================
-- Clipboard
-- =============================================================================

-- Copy to system clipboard
map({ "n", "v" }, "<leader>y", '"+y', { desc = "Copy to clipboard" })
map("n", "<leader>Y", '"+Y', { desc = "Copy line to clipboard" })

-- Paste from system clipboard
map({ "n", "v" }, "<leader>p", '"+p', { desc = "Paste from clipboard" })

-- =============================================================================
-- Quick Actions
-- =============================================================================

-- Quick quit
map("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit all" })

-- Lazygit
map("n", "<leader>gg", "<cmd>!lazygit<cr>", { desc = "Lazygit" })
