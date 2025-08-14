local servers = {}

servers["lua_ls"] = {}

if vim.fn.executable("go") == 1 then
	servers["gopls"] = {}
end

if vim.fn.executable("ruby") == 1 then
	servers["sorbet"] = {}
end

local on_attach = function(_, bufnr)
	local nmap = function(keys, func, desc)
		if desc then
			desc = "LSP: " .. desc
		end

		vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
	end

	nmap("<leader>cr", vim.lsp.buf.rename, "[R]e[n]ame")
	nmap("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
	nmap("<leader>cs", ":Telescope lsp_document_symbols<CR>", "[C]ode [s]earch")

	nmap("gd", ":Telescope lsp_definitions<CR>", "[G]oto [D]definition")
	nmap("gr", ":Telescope lsp_references<CR>", "[G]oto [R]eferences")
	nmap("ge", ":Telescope diagnostics<CR>", "[G]oto [R]eferences")
end

return {
	{
		"williamboman/mason.nvim",
		lazy = false,
		config = function()
			require("mason").setup()
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		lazy = false,
		opts = {
			ensure_installed = vim.tbl_keys(servers),
		},
	},
	{
		"neovim/nvim-lspconfig",
		lazy = false,
		config = function()
			local capabilities = vim.lsp.protocol.make_client_capabilities()
			local lspconfig = require("lspconfig")
			for server_name, settings in pairs(servers) do
				lspconfig[server_name].setup({
					capabilities = capabilities,
					on_attach = on_attach,
					settings = settings,
					filetypes = (servers[server_name] or {}).filetypes,
				})
			end
		end,
	},
}
