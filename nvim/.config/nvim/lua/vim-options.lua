vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")

vim.g.mapleader = " "
vim.opt.number = true
vim.opt.swapfile = false
vim.opt.clipboard = "unnamedplus"

-- Remove sign column background
vim.cmd([[highlight clear SignColumn]])

-- Remove line number background
vim.cmd([[highlight clear LineNr]])
vim.cmd([[highlight clear CursorLineNr]])

-- Navigate down: Browse and select subdirectory
vim.keymap.set('n', '<leader>cd', function()
  local cwd = vim.fn.getcwd()
  local dirs = vim.fn.systemlist('find "' .. cwd .. '" -mindepth 1 -maxdepth 1 -type d ! -name ".*" 2>/dev/null')
  
  if #dirs == 0 then
    print('No subdirectories found in: ' .. vim.fn.fnamemodify(cwd, ':~'))
    return
  end
  
  vim.ui.select(dirs, {
    prompt = 'Select directory (current: ' .. vim.fn.fnamemodify(cwd, ':~') .. ')',
    format_item = function(item)
      return vim.fn.fnamemodify(item, ':t')
    end,
  }, function(choice)
    if choice then
      vim.cmd('lcd ' .. vim.fn.fnameescape(choice))
      
      -- Update nvim-tree
      local api = require('nvim-tree.api')
      api.tree.change_root(choice)
      
      print('📁 ' .. vim.fn.fnamemodify(choice, ':~'))
    end
  end)
end, { desc = "Change directory (down)" })

-- Navigate up: Go to parent directory
vim.keymap.set('n', '<leader>cu', function()
  local parent = vim.fn.fnamemodify(vim.fn.getcwd(), ':h')
  vim.cmd('lcd ..')
  
  -- Update nvim-tree
  local api = require('nvim-tree.api')
  api.tree.change_root(parent)
  
  print('📁 ' .. vim.fn.fnamemodify(vim.fn.getcwd(), ':~'))
end, { desc = "Change directory (up)" })

-- Show current directory
vim.keymap.set('n', '<leader>cw', function()
  print('📁 ' .. vim.fn.fnamemodify(vim.fn.getcwd(), ':~'))
end, { desc = "Show current directory" })

-- Reset to where nvim was opened
vim.keymap.set('n', '<leader>cr', function()
  local start_dir = vim.fn.getenv('PWD')
  if start_dir and start_dir ~= vim.NIL then
    vim.cmd('lcd ' .. vim.fn.fnameescape(start_dir))
    
    -- Update nvim-tree
    local api = require('nvim-tree.api')
    api.tree.change_root(start_dir)
    
    print('📁 Reset to: ' .. vim.fn.fnamemodify(start_dir, ':~'))
  end
end, { desc = "Reset to initial directory" })

vim.api.nvim_set_hl(0, 'Normal', { bg = 'NONE' })
vim.api.nvim_set_hl(0, 'NormalFloat', { bg = 'NONE' })
vim.api.nvim_set_hl(0, 'LineNr', { bg = 'NONE' })
vim.api.nvim_set_hl(0, 'SignColumn', { bg = 'NONE' })
vim.api.nvim_set_hl(0, 'CursorLineNr', { bg = 'NONE' })

vim.keymap.set("n", "<leader>ml", "<cmd>vsplit<cr>")
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move to window below" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move to window above" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

-- Jump to next/previous diagnostic
vim.keymap.set("n", "]d", function()
  require("trouble").next({skip_groups = true, jump = true})
end, { desc = "Next diagnostic" })

vim.keymap.set("n", "[d", function()
  require("trouble").prev({skip_groups = true, jump = true})
end, { desc = "Previous diagnostic" })

-- Set up diagnostic signs and highlights
vim.diagnostic.config({
  signs = true,
  underline = true,
  virtual_text = true,
  update_in_insert = false,
})

-- Highlight the entire line with errors
vim.cmd([[
  highlight DiagnosticLineError guibg=#3f1f1f gui=NONE
  highlight DiagnosticLineWarn guibg=#3f3f1f gui=NONE
]])

-- Auto command to set line highlights
vim.api.nvim_create_autocmd("DiagnosticChanged", {
  callback = function()
    vim.diagnostic.show()
  end,
})

vim.g.clipboard = {
  name = 'win32yank',
  copy = {
    ['+'] = 'win32yank.exe -i --crlf',
    ['*'] = 'win32yank.exe -i --crlf',
  },
  paste = {
    ['+'] = 'win32yank.exe -o --lf',
    ['*'] = 'win32yank.exe -o --lf',
  },
  cache_enabled = 0,
}

-- reload all buffers
vim.opt.autoread = true
vim.opt.autowriteall = false  -- Don't auto-save

-- Force check on focus
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
  command = "silent! checktime",
})

vim.keymap.set("n", "<leader>r", function()
  vim.cmd("bufdo! edit!")
  print("All buffers force reloaded")
end, { desc = "Force reload all buffers" })

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
