vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")

vim.g.mapleader = " "
vim.opt.number = true
vim.opt.swapfile = false
vim.opt.clipboard = "unnamedplus"

vim.keymap.set("n", "<leader>ml", "<cmd>vsplit<cr>")
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move to window below" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move to window above" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

-- bind to close a window
vim.keymap.set("n", "<leader>k", "<cmd>close<CR>", { desc = "Close current window" })

vim.keymap.set("n", "<leader>fb", "<cmd>Telescope buffers sort_mru=true<cr>", { desc = "Find buffers (MRU)" })
vim.keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep<cr>", { desc = "Live grep" })
vim.keymap.set("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>", { desc = "Recent files" })

-- resize all windows
vim.keymap.set("n", "<C-Up>", ":resize +2<CR>", { desc = "Increase height" })
vim.keymap.set("n", "<C-Down>", ":resize -2<CR>", { desc = "Decrease height" })
vim.keymap.set("n", "<C-Right>", ":vertical resize +2<CR>", { desc = "Increase width" })
vim.keymap.set("n", "<C-Left>", ":vertical resize -2<CR>", { desc = "Increase width" })

-- Bonus: equalize all windows quickly
vim.keymap.set("n", "<leader>=", "<C-w>=", { desc = "Equal window sizes" })

-- In your init.lua or a separate config file
vim.api.nvim_create_autocmd("FileType", {
	pattern = "neo-tree",
	callback = function()
		vim.api.nvim_set_hl(0, "NeoTreeFileName", { fg = "#dde1e6" })
		vim.api.nvim_set_hl(0, "NeoTreeFileNameOpened", { fg = "#ffffff" })
	end,
})

-- Notes command - opens nvim in notes directory in temporary tmux window
vim.api.nvim_create_user_command('Notes', function()
  local notes_dir = vim.fn.expand('~/notes')
  
  -- Check if we're in tmux
  if vim.env.TMUX then
    -- Create new tmux window, cd to notes, open nvim with index.md
    vim.fn.system(string.format(
      "tmux new-window -n 'notes' -c '%s' 'nvim index.md'",
      notes_dir
    ))
  else
    -- If not in tmux, cd and open in current nvim
    vim.cmd('cd ' .. notes_dir)
    vim.cmd('edit index.md')
  end
end, {})
