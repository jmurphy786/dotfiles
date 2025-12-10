return {
	{
		"mason-org/mason-lspconfig.nvim",
		opts = {
			ensure_installed = {},
		},
		dependencies = {
			{ "mason-org/mason.nvim", opts = {} },
			"neovim/nvim-lspconfig",
		},
	},
	{
		"neovim/nvim-lspconfig",
		config = function()
			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			vim.lsp.config("ts_ls", {
				capabilities = capabilities,
			})

			vim.lsp.config("lua_ls", {
				capabilities = capabilities,
			})
			vim.lsp.enable("lua_ls")
			vim.lsp.enable("ts_ls")
			vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
			-- Go to definition in NEW split on the right
			vim.keymap.set("n", "<leader>gd", function()
				vim.cmd("rightbelow vsplit") -- Forces split to the right
				vim.lsp.buf.definition()
			end, { desc = "Go to definition in vertical split" }) --vim.keymap.set("n", "gd", vim.lsp.buf.definition, {})
			vim.keymap.set({ "n" }, "<leader>ca", vim.lsp.buf.code_action, {})
		end,
	},
}
