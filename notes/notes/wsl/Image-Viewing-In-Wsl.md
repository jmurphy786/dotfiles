# WSL Neovim Markdown Setup Guide

A complete guide to setting up markdown-oxide, image support, yazi, and WezTerm for a PKM workflow on WSL.

---

## 1. System Dependencies

```bash
# Core dependencies
sudo apt install imagemagick libreadline-dev luarocks
sudo apt install imagemagick librsvg2-bin librsvg2-dev

## xclip may not be needed
sudo apt install python3-pip xclip fzf

# Python dependencies
pip3 install neovim --break-system-packages
pip3 install pillow --break-system-packages

# Rust (required for markdown-oxide and resvg)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env
rustup update stable
```

---

## 2. Installing markdown-oxide

```bash
cargo install --locked --git https://github.com/Feel-ix-343/markdown-oxide.git markdown-oxide
```

Or via Mason inside Neovim:
```
:MasonInstall markdown-oxide
```

---

## 3. Installing harper-ls (Grammar/Spell Checking)

```
:MasonInstall harper-ls
```

---

## 4. Installing glow (Markdown Preview)

```bash
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
sudo apt update && sudo apt install glow
```

---

## 5. Installing resvg (SVG support for yazi)

```bash
cargo install resvg
```

---

## 6. Vault Setup

Create your notes folder and add a `.moxide.toml` config file:

```bash
mkdir -p ~/notes-work/daily
mkdir -p ~/notes-work/images
```

Create `~/notes-work/.moxide.toml`:
```toml
daily_notes_folder = "daily"
dailynote = "%Y-%m-%d"
```

> **Important on WSL**: Make sure the file has no CRLF line endings.
> Check with: `cat -A ~/notes-work/.moxide.toml`
> Fix with: `sed -i 's/\r//' ~/notes-work/.moxide.toml`

---

## 7. Neovim Plugin Config

### mason-lspconfig.nvim

```lua
{
  "mason-org/mason-lspconfig.nvim",
  opts = {
    ensure_installed = {
      "ts_ls",
      "lua_ls",
      "harper_ls",
    },
    automatic_enable = {
      exclude = { "roslyn_ls" },
    },
  },
  dependencies = {
    {
      "mason-org/mason.nvim",
      opts = {
        registries = {
          "github:mason-org/mason-registry",
          "github:Crashdummyy/mason-registry",
        }
      },
    },
    "neovim/nvim-lspconfig",
  },
},
```

### nvim-lspconfig

```lua
{
  "neovim/nvim-lspconfig",
  config = function()
    local capabilities = require("cmp_nvim_lsp").default_capabilities()

    vim.lsp.config('markdown_oxide', {
      capabilities = vim.tbl_deep_extend(
        'force',
        capabilities,
        {
          workspace = {
            didChangeWatchedFiles = {
              dynamicRegistration = true,
            },
          },
        }
      ),
      on_attach = function(client, bufnr)
        if client.name == "markdown_oxide" then
          vim.api.nvim_create_user_command(
            "Daily",
            function(args)
              local input = args.args
              if input == "" then input = "today" end
              vim.lsp.buf.execute_command({ command = "jump", arguments = { input } })
            end,
            { desc = "Open daily note", nargs = "*" }
          )
        end
      end,
    })

    vim.lsp.enable('markdown_oxide')
    vim.lsp.enable("harper_ls")
    vim.lsp.enable("lua_ls")
    vim.lsp.enable("ts_ls")
  end,
},
```

### nvim-cmp

```lua
{
  "hrsh7th/nvim-cmp",
  config = function()
    local cmp = require("cmp")
    require("luasnip.loaders.from_vscode").lazy_load()
    cmp.setup({
      snippet = {
        expand = function(args)
          require("luasnip").lsp_expand(args.body)
        end,
      },
      window = {
        completion = cmp.config.window.bordered(),
        documentation = cmp.config.window.bordered(),
      },
      mapping = cmp.mapping.preset.insert({
        ["<C-b>"] = cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = cmp.mapping.scroll_docs(4),
        ["<C-Space>"] = cmp.mapping.complete(),
        ["<C-e>"] = cmp.mapping.abort(),
        ["<CR>"] = cmp.mapping.confirm({ select = true }),
      }),
      sources = cmp.config.sources({
        {
          name = "nvim_lsp",
          option = {
            markdown_oxide = {
              keyword_pattern = [[\(\k\| \|\/\|#\)\+]]
            }
          }
        },
        { name = "luasnip" },
        { name = "path" },
      }, {
        { name = "buffer" },
      }),
    })
  end,
},
```

### image.nvim

```lua
{
  "3rd/image.nvim",
  build = false,
  opts = {
    processor = "magick_cli",
    backend = "sixel",
    integrations = {
      markdown = {
        enabled = true,
        only_render_image_at_cursor = false,
        filetypes = { "markdown" },
      },
    },
    max_height_window_percentage = 50,
    hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.svg" },
  },
},
```

---

## 8. Daily Note Template (autocmd)

Add to your Neovim config:

```lua
vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "*/daily/*.md",
  callback = function()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local is_empty = #lines == 0 or (#lines == 1 and lines[1] == "")
    if is_empty then
      local date = vim.fn.expand("%:t:r")
      vim.api.nvim_buf_set_lines(0, 0, -1, false, {
        "# " .. date,
        "",
        "## Notes",
        "",
        "## Tasks",
        "",
      })
    end
  end,
})
```

---

## 9. Clipboard Image Paste Keymap

Add to your Neovim config:

```lua
vim.keymap.set("n", "<leader>pi", function()
  local img_dir = vim.fn.expand("%:p:h") .. "/images"
  vim.fn.mkdir(img_dir, "p")
  local tmp_win = "C:\\Users\\jordan.murphy\\AppData\\Local\\Temp\\nvim_paste.png"
  local ps_cmd = string.format(
    'powershell.exe -c "Add-Type -AssemblyName System.Windows.Forms; \\$img = [System.Windows.Forms.Clipboard]::GetImage(); if (\\$img) { \\$img.Save(\'%s\') }"',
    tmp_win
  )
  vim.fn.system(ps_cmd)
  vim.fn.system("sleep 1")

  vim.ui.input({ prompt = "Image name: " }, function(name)
    local filename
    if name and name ~= "" then
      filename = name .. ".png"
    else
      filename = os.date("%Y-%m-%d_%H-%M-%S") .. ".png"
    end

    local filepath = img_dir .. "/" .. filename
    local tmp_wsl = vim.fn.system("wslpath -u '" .. tmp_win:gsub("\\", "\\\\") .. "'"):gsub("\n", "")
    vim.fn.system("cp " .. tmp_wsl .. " " .. filepath)

    if vim.fn.filereadable(filepath) == 1 then
      local rel_path = "images/" .. filename
      vim.api.nvim_put({ "![](" .. rel_path .. ")" }, "c", true, true)
      vim.notify("Image saved: " .. rel_path)
    else
      vim.notify("No image in clipboard or save failed", vim.log.levels.ERROR)
    end
  end)
end, { desc = "Paste image from clipboard" })
```

> **Note**: Update the `tmp_win` path to match your Windows username.

---

## 10. Glow Preview Keymap

```lua
vim.keymap.set("n", "<leader>pg", function()
  local file = vim.fn.expand("%:p")
  vim.cmd("split | terminal glow " .. file)
end, { desc = "Preview with glow" })
```

---

## 11. Open Image in Windows Keymap

```lua
vim.keymap.set("n", "<leader>vi", function()
  local file = vim.fn.expand("<cfile>")
  local abs = vim.fn.expand("%:p:h") .. "/" .. file
  local win_path = vim.fn.system("wslpath -w " .. abs):gsub("\n", "")
  vim.fn.system("explorer.exe " .. win_path)
end, { desc = "Open image in Windows" })
```

---

## 12. Daily Note Keybind (hardcoded, works anywhere)

```lua
vim.keymap.set("n", "<leader>dn", function()
  local date = os.date("%Y-%m-%d")
  local path = vim.fn.expand("~/notes-work/daily/") .. date .. ".md"
  vim.cmd("edit " .. path)
end, { desc = "Open daily note" })
```

---

## 13. WezTerm Config

### Enable Kitty Graphics

```lua
config.enable_kitty_graphics = true
```

### Notes Picker (fzf split pane)

```lua
{
  key = "n",
  mods = "CTRL|SHIFT",
  action = wezterm.action.SplitPane({
    direction = "Down",
    size = { Percent = 30 },
    command = {
      args = {
        "bash", "-c",
        [[
          selected=$(echo -e "notes\nnotes-work" | fzf --prompt="Notes: " --height=10 --border)
          if [ -n "$selected" ]; then
            cd ~/$selected && nvim main.md
          fi
        ]],
      },
    },
  }),
},
```

---

## 14. Yazi Config (`~/.config/yazi/yazi.toml`)

```toml
[preview]
image_filter = "nearest"
image_quality = 75
max_width = 900
max_height = 800

[[previewer]]
mime = "image/{avif,heic,jxl,svg+xml}"
run = "magick"
```

Since ImageMagick 6 uses `convert` instead of `magick`, create a wrapper:

```bash
sudo nano /usr/local/bin/magick
```

Add:
```bash
#!/bin/bash
convert "$@"
```

Make it executable:
```bash
sudo chmod +x /usr/local/bin/magick
```

---

## 15. Using Daily Notes

Once set up, use `:Daily` commands inside any markdown buffer:

```
:Daily today
:Daily tomorrow
:Daily yesterday
:Daily next monday
:Daily prev
:Daily next
:Daily +3
:Daily -3
```

---

## 16. Using markdown-oxide Completions

In any markdown file:

- `[[` - file link completions
- `[[file#` - heading completions within a file  
- `#` - tag completions
- `![[` - wikilink image/file embed
- `![](./` then `<C-Space>` - path completions for images

---

## Troubleshooting

### `:Daily` not working
- Make sure you are in a `.md` buffer first
- Run `:LspInfo` to confirm `markdown_oxide` is attached
- Run `:command Daily` to confirm the command exists

### CRLF issues on WSL
```bash
sed -i 's/\r//' ~/notes-work/.moxide.toml
```

### LspRestart showing null-ls error
Use this instead:
```lua
:lua vim.lsp.stop_client(vim.lsp.get_clients({name="markdown_oxide"}))
```

### image.nvim not rendering
- Run `:ImageReport` to see what image.nvim detects
- Make sure `convert --version` works
- Try `only_render_image_at_cursor = true` for better performance on WSL

### SVG not showing in yazi
```bash
cargo install resvg
rustup update stable  # if Rust version is too old
```
