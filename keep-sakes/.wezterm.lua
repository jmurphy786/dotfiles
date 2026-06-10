-- WezTerm Keybindings Documentation by dragonlobster
-- ===================================================
-- Leader Key:
-- The leader key is set to CTRL + b, with a timeout of 2000 milliseconds (2 seconds).
-- To execute any keybinding, press the leader key (CTRL + b) first, then the corresponding key.

-- Keybindings:
-- 1. Tab Management:
--    - LEADER + c: Create a new tab in the current pane's domain.
--    - LEADER + x: Close the current pane (with confirmation).
--    - LEADER + b: Switch to the previous tab.
--    - LEADER + n: Switch to the next tab.
--    - LEADER + <number>: Switch to a specific tab (0-9).

-- 2. Pane Splitting:
--    - LEADER + v: Split the current pane horizontally.
--    - LEADER + s: Split the current pane vertically.
-- 3. Pane Navigation:
--    - LEADER + h: Move to the pane on the left.
--    - LEADER + j: Move to the pane below.
--    - LEADER + k: Move to the pane above.
--    - LEADER + l: Move to the pane on the right.

-- 4. Pane Resizing:
--    - LEADER + LeftArrow: Enter resize mode, resize left.
--    - LEADER + RightArrow: Enter resize mode, resize right.
--    - LEADER + DownArrow: Enter resize mode, resize down.
--    - LEADER + UpArrow: Enter resize mode, resize up.
--    - Escape/Enter: Exit resize mode.

-- 5. Status Line:
--    - The status line indicates when the leader key is active, displaying an ocean wave emoji.

-- Pull in the wezterm API

local wezterm = require "wezterm"
local act = wezterm.action

local config = {}
if wezterm.config_builder then
  config = wezterm.config_builder()
end
config.enable_kitty_graphics = true

config.set_environment_variables = {
  TERM = "wezterm",
}

--[[
============================
Performance
============================
]] --
config.max_fps = 60
config.animation_fps = 1
config.cursor_blink_rate = 0
--config.term = "wezterm"

--[[
============================
Custom Configuration
============================
]] --
local tab_style = "square"

-- leader active indicator prefix
local leader_prefix = utf8.char(0x1f30a) -- ocean wave

--[[
============================
WSL Domain
============================
]] --
local DEFAULT_DOMAIN = "WSL:dotfiles-test"
-- Remove config.default_prog = { 'wsl.exe' }
-- WslDomain handles this natively and more efficiently
-- The fix - use ConPTY via Windows Terminal

config.default_domain = "WSL:dotfiles-test"
config.wsl_domains = {
  {
    name = "WSL:dotfiles-test",
    distribution = "dotfiles-test",
    default_cwd = "~",
  },
}

--[[
============================
Font
============================
]] --

config.font = wezterm.font("JetBrains Mono")

config.font_size = 14

config.window_decorations = "RESIZE"
config.window_background_opacity = 1

local bar = wezterm.plugin.require("https://github.com/adriankarlen/bar.wezterm")
bar.apply_to_config(config)

---------------------------------------
-- FUNCTIONS
-- -----------------------------------

-- near the top, after local mux = wezterm.mux
local mux = wezterm.mux

local function popup_window(window, pane, cmd)
  local screens = wezterm.gui.screens()
  local active = screens.active
  local sw = active.width
  local sh = active.height

  local popup_w = math.floor(sw * 0.55)
  local popup_h = math.floor(sh * 0.45)
  local popup_x = math.floor((sw - popup_w) / 2)
  local popup_y = math.floor((sh - popup_h) / 2)

  local full_cmd = 'glazewm.exe command "set-floating" 2>/dev/null'
  if cmd then
    full_cmd = full_cmd .. ' && ' .. cmd
  end

  local tab, popup_pane, popup_win = mux.spawn_window {
    domain = { DomainName = DEFAULT_DOMAIN },
    width = math.floor(popup_w / 9),
    height = math.floor(popup_h / 18),
    args = { 'bash', '--login', '-c', full_cmd },
  }

  local gui_popup = popup_win:gui_window()
  gui_popup:set_position(popup_x, popup_y)
  gui_popup:focus()
end


--[[
============================
Colors
============================
]] --

local color_scheme = "Catppuccin Macchiato"
config.color_scheme = color_scheme

local scheme_colors = {
  catppuccin = {
    macchiato = {
      rosewater = "f4dbd6",
      flamingo  = "f0c6c6",
      pink      = "f5bde6",
      mauve     = "c6a0f6",
      red       = "ed8796",
      maroon    = "ee99a0",
      peach     = "#f5a97f",
      yellow    = "#eed49f",
      green     = "#a6da95",
      teal      = "#8bd5ca",
      sky       = "#91d7e3",
      sapphire  = "#7dc4e4",
      blue      = "#8aadf4",
      lavender  = "#b7bdf8",
      text      = "#cad3f5",
      crust     = "#181926",
    }
  }
}

local colors = {
  border                  = scheme_colors.catppuccin.macchiato.lavender,
  tab_bar_active_tab_fg   = scheme_colors.catppuccin.macchiato.mauve,
  tab_bar_active_tab_bg   = scheme_colors.catppuccin.macchiato.crust,
  tab_bar_text            = scheme_colors.catppuccin.macchiato.crust,
  arrow_foreground_leader = scheme_colors.catppuccin.macchiato.lavender,
  arrow_background_leader = scheme_colors.catppuccin.macchiato.crust,
}

--[[
============================
Border
============================
]] --

config.window_frame = {
  border_left_width    = "0cell",
  border_right_width   = "0cell",
  border_bottom_height = "0cell",
  border_top_height    = "0cell",
  border_left_color    = colors.border,
  border_right_color   = colors.border,
  border_bottom_color  = colors.border,
  border_top_color     = colors.border,
}



--[[
============================
Shortcuts
============================
]] --

config.leader = {
  key = "Space",
  mods = "CTRL",
}

config.keys = {
  {
    mods = "LEADER",
    key = "x",
    action = act.CloseCurrentPane { confirm = false }
  },
  {
    mods = "CTRL",
    key = "w",
    action = act.CloseCurrentTab{ confirm = false }
  },
  {
    key = 'n',
    mods = 'LEADER',
    action = wezterm.action_callback(function(window, pane)
      popup_window(window, pane, 'cd ~/personal/notes && nvim main.md')
    end),
  },
  {
    key = 'm',
    mods = 'LEADER',
    action = wezterm.action_callback(function(window, pane)
      popup_window(window, pane, 'cd ~/work-notes && nvim main.md')
    end),
  },
  {
    key = 'w',
    mods = 'LEADER',
    action = act.PromptInputLine {
      description = 'Enter new workspace name',
      action = wezterm.action_callback(function(window, pane, line)
        if line then
          window:perform_action(act.SwitchToWorkspace { name = line }, pane)
        end
      end),
    },
  },
  {
    key = '/',
    mods = 'CTRL',
    action = act.ShowLauncherArgs { flags = 'WORKSPACES' },
  },
  {
    mods = "LEADER",
    key = "s",
    action = act.SplitHorizontal { domain = "CurrentPaneDomain" },
  },
  {
    mods = "LEADER",
    key = "v",
    action = act.SplitVertical { domain = "CurrentPaneDomain" },
  },
  {
    mods = "LEADER",
    key = "R",
    action = act.PromptInputLine {
      description = "Enter new workspace name",
      action = wezterm.action_callback(function(window, pane, line)
        if line then
          wezterm.mux.rename_workspace(window:active_workspace(), line)
        end
      end),
    },
  },
  {
    mods = "CTRL",
    key = "t",
    action = act.SpawnTab "CurrentPaneDomain",
  },
  { key = 'h', mods = 'LEADER', action = act.ActivatePaneDirection('Left') },
  { key = 'j', mods = 'LEADER', action = act.ActivatePaneDirection('Down') },
  { key = 'k', mods = 'LEADER', action = act.ActivatePaneDirection('Up') },
  { key = 'l', mods = 'LEADER', action = act.ActivatePaneDirection('Right') },
  {
    mods = "LEADER",
    key = "r",
    action = act.PromptInputLine {
      description = "Enter new tab name",
      action = wezterm.action_callback(function(window, pane, line)
        if line then
          window:active_tab():set_title(line)
        end
      end),
    },
  },
  {
    mods = "LEADER",
    key = "d",
    action = wezterm.action_callback(function(window, pane)
      local mux_win = window:mux_window()
      window:perform_action(act.SwitchWorkspaceRelative(-1), pane)
      for _, tab in ipairs(mux_win:tabs()) do
        tab:activate()
        window:perform_action(act.CloseCurrentTab { confirm = false }, pane)
      end
    end),
  },
  -- Resize mode - press LEADER + arrow to enter, keep pressing to resize
  {
    mods = "LEADER",
    key = "LeftArrow",
    action = act.Multiple {
      act.AdjustPaneSize { "Left", 5 },
      act.ActivateKeyTable { name = "resize_pane", one_shot = false },
    }
  },
  {
    mods = "LEADER",
    key = "RightArrow",
    action = act.Multiple {
      act.AdjustPaneSize { "Right", 5 },
      act.ActivateKeyTable { name = "resize_pane", one_shot = false },
    }
  },
  {
    mods = "LEADER",
    key = "DownArrow",
    action = act.Multiple {
      act.AdjustPaneSize { "Down", 5 },
      act.ActivateKeyTable { name = "resize_pane", one_shot = false },
    }
  },
  {
    mods = "LEADER",
    key = "UpArrow",
    action = act.Multiple {
      act.AdjustPaneSize { "Up", 5 },
      act.ActivateKeyTable { name = "resize_pane", one_shot = false },
    }
  },
}

config.key_tables = {
  resize_pane = {
    { key = "LeftArrow",  action = act.AdjustPaneSize { "Left", 5 } },
    { key = "RightArrow", action = act.AdjustPaneSize { "Right", 5 } },
    { key = "DownArrow",  action = act.AdjustPaneSize { "Down", 5 } },
    { key = "UpArrow",    action = act.AdjustPaneSize { "Up", 5 } },
    { key = "Escape",     action = act.PopKeyTable },
    { key = "Enter",      action = act.PopKeyTable },
  },
}

for i = 1, 9 do
  table.insert(config.keys, {
    key = tostring(i),
    mods = "LEADER",
    action = act.ActivateTab(i - 1),
  })
end

--[[
============================
Tab Bar
============================
]] --

config.hide_tab_bar_if_only_one_tab = false
config.tab_bar_at_bottom = true
config.use_fancy_tab_bar = false
config.tab_and_split_indices_are_zero_based = false

local function tab_title(tab_info)
  local title = tab_info.tab_title
  if title and #title > 0 then return title end
  return tab_info.active_pane.title
end

wezterm.on(
  "format-tab-title",
  function(tab, tabs, panes, config, hover, max_width)
    local index = tab.tab_index + 1
    local title = " " .. index .. ": " .. tab_title(tab) .. " "
    local left_edge_text = ""
    local right_edge_text = ""

    if tab_style == "rounded" then
      title = tab.tab_index .. ": " .. tab_title(tab)
      title = wezterm.truncate_right(title, max_width - 2)
      left_edge_text = wezterm.nerdfonts.ple_left_half_circle_thick
      right_edge_text = wezterm.nerdfonts.ple_right_half_circle_thick
    end

    if tab.is_active then
      return {
        { Background = { Color = colors.tab_bar_active_tab_bg } },
        { Foreground = { Color = colors.tab_bar_active_tab_fg } },
        { Text = left_edge_text },
        { Background = { Color = colors.tab_bar_active_tab_fg } },
        { Foreground = { Color = colors.tab_bar_text } },
        { Text = title },
        { Background = { Color = colors.tab_bar_active_tab_bg } },
        { Foreground = { Color = colors.tab_bar_active_tab_fg } },
        { Text = right_edge_text },
      }
    else
      return {
        { Text = title },
      }
    end
  end
)
--[[
============================
Leader Active Indicator
============================
]] --

return config

