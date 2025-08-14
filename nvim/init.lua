local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

require("options")
require("keys")
require("lazy").setup("plugins")
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "json", "jsonc" },
  callback = function()
    vim.bo.expandtab = true   -- Use spaces instead of tabs
    vim.bo.tabstop = 2        -- Show tabs as 2 spaces
    vim.bo.shiftwidth = 2     -- Use 2 spaces for indentation
    vim.cmd('retab')          -- Convert any existing tabs to spaces
  end,
})
