return {
	"folke/trouble.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	opts = {},
	config = function()
		require("trouble").setup()
		-- Keybindings
		vim.keymap.set("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Diagnostics (Trouble)" })
		vim.keymap.set(
			"n",
			"<leader>xX",
			"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
			{ desc = "Buffer Diagnostics (Trouble)" }
		)
		vim.keymap.set("n", "<leader>td", "<cmd>Trouble loclist toggle<cr>", { desc = "Location List (Trouble)" })
		vim.keymap.set("n", "<leader>tb", "<cmd>Trouble qflist toggle<cr>", { desc = "Quickfix List (Trouble)" })
	end,
}
