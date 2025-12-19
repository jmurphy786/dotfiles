return {
  'eldritch-theme/eldritch.nvim',
  lazy = false,
  priority = 1000,
  config = function()
    require('eldritch').setup({
      transparent = true,
      terminal_colors = true,
      styles = {
        comments = { italic = true },
        keywords = { italic = true },
      },
    })
    
    -- Choose one:
    vim.cmd('colorscheme eldritch-dark')       -- Default palette
    -- vim.cmd('colorscheme eldritch-dark')  -- Darker palette
  end,
}
