return {
        "NLKNguyen/papercolor-theme",
	"catppuccin/nvim",
	lazy = false,
	priority = 1000,
	opts = {},
	config = function()
		vim.cmd.colorscheme("papercolor-theme")
	end,
}
