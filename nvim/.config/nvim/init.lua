local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({
			{ "Failed to clone lazy.nvim:\n", "ErrorMsg" },
			{ out, "WarningMsg" },
			{ "\nPress any key to exit..." },
		}, true, {})
		vim.fn.getchar()
		os.exit(1)
	end
end
vim.opt.rtp:prepend(lazypath)

-- Claude AI Integration
vim.keymap.set('n', '<leader>ma', function()
  local current_file = vim.fn.expand('%:p')
  
  if current_file == '' then
    print('No file open')
    return
  end
  
  if not current_file:match('%.md$') then
    print('Not a markdown file: ' .. current_file)
    return
  end
  
  -- Save the file
  vim.cmd('write')
  
  -- Run claude-append in a terminal buffer
  vim.cmd('split | terminal claude-append "' .. current_file .. '"')
  
  -- Set up autocmd to reload the file when terminal closes
  vim.cmd([[
    autocmd TermClose <buffer> ++once lua vim.defer_fn(function()
      vim.cmd('close')
      vim.cmd('edit!')
      vim.cmd('normal! G')
    end, 100)
  ]])
end, { desc = 'Claude Append' })

vim.keymap.set('n', '<leader>mn', function()
  vim.cmd('split | terminal claude-new')
  
  vim.cmd([[
    autocmd TermClose <buffer> ++once lua vim.defer_fn(function()
      vim.cmd('close')
      local newest = vim.fn.system('ls -t ~/claude-convos/*.md 2>/dev/null | head -1'):gsub('%s+', '')
      if newest ~= '' then
        vim.cmd('edit ' .. newest)
      end
    end, 100)
  ]])
end, { desc = 'Claude New' })

-- Debug: print confirmation that keybindings are loaded
print('Claude keybindings loaded: <leader>ma and <leader>mn')

-- Add Mason bin to PATH (IMPORTANT: before loading plugins)
vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin:" .. vim.env.PATH

require("vim-options")
require("lazy").setup("plugins")
require('luasnip.loaders.from_lua').load({paths = "~/.config/nvim/luasnippets/"})
