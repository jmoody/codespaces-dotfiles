if vim.fn.executable("node") == 0 then
	return {}
end

return {
	"github/copilot.vim",
	config = function()
		-- Disable Copilot for *.md files
		vim.g.copilot_filetypes = {
			markdown = false,
		}
	end,
}
