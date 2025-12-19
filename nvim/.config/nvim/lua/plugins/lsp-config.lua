return {
  {
    "mason-org/mason-lspconfig.nvim",
    opts = {
      ensure_installed = {
        "omnisharp", -- C# LSP
        "ts_ls", -- TypeScript
        "lua_ls", -- Lua
        "marksman", -- Markdown LSP
      },
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
      
      -- TypeScript
      vim.lsp.config("ts_ls", {
        capabilities = capabilities,
      })
      
      -- Lua
      vim.lsp.config("lua_ls", {
        capabilities = capabilities,
      })
      
      -- Markdown
      vim.lsp.config("marksman", {
        capabilities = capabilities,
      })
      
      -- C# / OmniSharp - with full path
      local omnisharp_bin = vim.fn.stdpath("data") .. "/mason/packages/omnisharp/OmniSharp"
      vim.lsp.config("omnisharp", {
        capabilities = capabilities,
        cmd = { omnisharp_bin, "--languageserver", "--hostPID", tostring(vim.fn.getpid()) },
        root_markers = { "*.sln", "*.csproj", ".git" },
      })
      
      -- Enable LSPs
      vim.lsp.enable("lua_ls")
      vim.lsp.enable("ts_ls")
      vim.lsp.enable("omnisharp")
      vim.lsp.enable("marksman")
      
      -- Keymaps
      vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
      vim.keymap.set("n", "<leader>gd", function()
        vim.lsp.buf.definition()
      end, { desc = "Go to definition" })
      vim.keymap.set("n", "<leader>gD", function()
        vim.cmd("rightbelow vsplit")
        vim.lsp.buf.definition()
      end, { desc = "Go to definition in vertical split" })
      vim.keymap.set({ "n" }, "<leader>ca", vim.lsp.buf.code_action, {})
    end,
  },
}
