return {
	"stevearc/conform.nvim",
	config = function()
		local conform = require("conform")
		conform.formatters.rubocop = {
			command = "bundle",
			prepend_args = { "exec", "rubocop" },
		}
		conform.setup({
			formatters_by_ft = {
				ruby = { "rubocop" },
				["*"] = { "codespell" },
				["_"] = { "trim_whitespace" },
			},
		})

		vim.api.nvim_create_user_command("Format", function()
			require("conform").format({
				async = true,
				timeout_ms = 1000,
				lsp_format = "fallback",
			})
		end, {})

		vim.keymap.set("n", "<leader>gf", ":Format<CR>", { desc = "Format code" })
	end
}
