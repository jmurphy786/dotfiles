return {
	"nyoom-engineering/oxocarbon.nvim",
	lazy = false,
	priority = 1000,
	config = function()
		vim.opt.background = "dark"
		vim.cmd.colorscheme("oxocarbon")

		-- Make background transparent (terminal opacity controls the level)
		vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
		vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
		vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
		vim.api.nvim_set_hl(0, "SignColumn", { bg = "none" })

		-- Force the color without any links
		vim.api.nvim_set_hl(0, "NeoTreeFileName", { fg = "#dde1e6", default = false })
		vim.api.nvim_set_hl(0, "NeoTreeFileNameOpened", { fg = "#ffffff", default = false })
	end,
}
