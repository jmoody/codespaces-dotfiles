-- Set leaders
vim.g.mapleader = ","
vim.g.maplocalleader = ","

-- Make line numbers default
vim.wo.number = true
vim.wo.relativenumber = false

-- Sync clipboard between OS and Neovim.
vim.o.clipboard = "unnamedplus"

-- Save undo history
vim.o.undofile = true

-- Case-insensitive searching UNLESS \C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep signcolumn on by default
vim.wo.signcolumn = "yes"

-- highlight current line
vim.o.cursorline = true

