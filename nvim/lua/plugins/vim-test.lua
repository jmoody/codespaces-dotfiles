return {
	"vim-test/vim-test",
	dependencies = {
		"preservim/vimux",
	},
	config = function()
		vim.keymap.set("n", "<leader>tt", ":TestNearest<CR>", { desc = "Run test" })
		vim.keymap.set("n", "<leader>tT", ":TestFile<CR>", { desc = "Run test file" })
		vim.keymap.set("n", "<leader>ta", ":TestSuite<CR>", { desc = "Run test suite" })
		vim.keymap.set("n", "<leader>tl", ":TestLast<CR>", { desc = "Run last test" })
		vim.keymap.set("n", "<leader>tg", ":TestVisit<CR>", { desc = "Visit test file" })
		vim.cmd("let test#strategy = 'vimux'")
	end,
}
