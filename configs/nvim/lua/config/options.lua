-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua

local opt = vim.opt

-- =============================================================================
-- Basic Settings
-- =============================================================================

-- Indentation
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4
opt.expandtab = true

-- Line numbers (static, not relative)
opt.number = true
opt.relativenumber = false

-- Clipboard (sync with system)
opt.clipboard = "unnamedplus"

-- No swap/backup files
opt.swapfile = false
opt.backup = false
opt.writebackup = false

-- Undo persistence
opt.undofile = true
opt.undolevels = 10000

-- =============================================================================
-- DISABLE ANNOYING FEATURES
-- =============================================================================

-- Disable smooth scrolling
opt.smoothscroll = false

-- Plain markdown: no concealment/rendering, just syntax highlighting
opt.conceallevel = 0

-- Hide tab indicators (LazyVim default shows ">")
opt.list = false

-- Disable LazyVim's inlay hints by default
vim.g.lazyvim_inlay_hints = false

-- =============================================================================
-- UI Settings
-- =============================================================================

-- Disable line wrapping
opt.wrap = false

-- Show column at 80 characters
opt.colorcolumn = "80"

-- Better splits
opt.splitright = true
opt.splitbelow = true

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true

-- Mouse
opt.mouse = "a"

-- Scrolloff
opt.scrolloff = 8
opt.sidescrolloff = 8

-- Update time
opt.updatetime = 200
opt.timeoutlen = 300

-- Sign column
opt.signcolumn = "yes"

-- True color support
opt.termguicolors = true

-- =============================================================================
-- Filetype-Specific Settings
-- =============================================================================

-- Elixir/Phoenix: 2-space indentation (community convention)
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "elixir", "eelixir", "heex", "surface" },
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.softtabstop = 2
  end,
})
