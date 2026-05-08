-- Set leaders
vim.g.mapleader = ","
vim.g.maplocalleader = ","

-- turn off search highlight
vim.api.nvim_set_keymap('n', '<leader><space>', ':nohlsearch<CR>', { noremap = true, silent = true })

vim.opt.background = "light"
vim.opt.termguicolors = true

-- Make line numbers default
vim.wo.number = true
vim.wo.relativenumber = false

-- Sync clipboard between OS and Neovim.
-- vim.o.clipboard = "unnamedplus"

-- Save undo history
vim.o.undofile = true

-- Case-insensitive searching UNLESS \C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep signcolumn on by default
vim.wo.signcolumn = "yes"

-- highlight current line
vim.o.cursorline = true

vim.api.nvim_create_autocmd("FileType", {
  pattern = "sh",
  callback = function()
    vim.bo.shiftwidth = 2
    vim.bo.tabstop = 2
    vim.bo.expandtab = true
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "dockerfile",
  callback = function()
    vim.bo.shiftwidth = 4
    vim.bo.tabstop = 4
    vim.bo.expandtab = true
  end,
})

