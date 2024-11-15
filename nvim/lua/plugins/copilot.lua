if vim.fn.executable("node") == 0 then
	return {}
end

return {
	"github/copilot.vim",
}
