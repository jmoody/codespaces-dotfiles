return {
	"nvim-telescope/telescope.nvim",
	branch = "0.1.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		{
			"nvim-telescope/telescope-fzf-native.nvim",
			build = "make",
		},

	},
	config = function()
		local telescope = require("telescope")
		telescope.setup({
			defaults = {
				layout_strategy = "vertical",
				layout_config = {
					mirror = true,
					prompt_position = "top",
				},
			},
			pickers = {
				find_files = {
					hidden = true,
				},
			},
		})
		-- Enable telescope fzf native, if installed
		pcall(telescope.load_extension, "fzf")

		local builtin = require("telescope.builtin")
		vim.keymap.set("n", "<leader>sf", builtin.find_files, { desc = "[f]ind [f]iles" })
		vim.keymap.set("n", "<leader>sg", builtin.live_grep, { desc = "[f]ind [g]rep" })
		vim.keymap.set("n", "<leader>sh", builtin.help_tags, { desc = "[f]ind [h]elp" })
		vim.keymap.set("n", "<leader>sr", builtin.resume, { desc = "[f]ind [r]esume" })
		vim.keymap.set("n", "<leader>sd", builtin.diagnostics, { desc = "[f]ind [r]esume" })

		-- shorter versions
		vim.keymap.set("n", "<leader><leader>", builtin.find_files, { desc = "find files" })
		vim.keymap.set("n", "<leader>,", builtin.buffers, { desc = "find buffers" })
	end,
}
