local wezterm = require("wezterm")

local config = {}
if wezterm.config_builder then
	config = wezterm.config_builder()
end

config.enable_tab_bar = false
config.enable_kitty_graphics = true
-- Report Esc as CSI 27 u instead of a bare 0x1b byte, so herdr doesn't have to
-- wait out a timeout to tell a lone Esc from the start of an Alt/CSI sequence.
config.enable_kitty_keyboard = true
config.bypass_mouse_reporting_modifiers = "SHIFT"
config.set_environment_variables = {
	TERM = "wezterm",
}
config.cursor_blink_rate = 0
config.wsl_domains = {
	{
		name = "WSL:dotfiles-test", -- match your actual distro name (run `wsl -l -v` to check)
		distribution = "dotfiles-test",
		default_cwd = "~",
		default_prog = { "bash", "-l" },
	},
}

config.default_domain = "WSL:dotfiles-test"


config.font = wezterm.font_with_fallback({ "JetBrainsMono Nerd Font", "JetBrains Mono", "Noto Color Emoji" })

config.font_size = 14
-- Zooming changes the row/column count instead of resizing the window, so it
-- can't grow past the laptop screen.
config.adjust_window_size_when_changing_font_size = false
config.window_decorations = "RESIZE"
config.window_background_opacity = 0.90

--config.color_scheme = "Catppuccin Mocha"

--[[ ============================
Colors
============================
]]
--


--[[
============================
Shortcuts
============================
]]
--

-- One tab per herdr machine view, found by title and created on first use:
--   ctrl+shift+r      "all": the normal multi-machine herdr
--   ctrl+shift+1..9   one tab per entry in `machines` below (1-3 DevPod, 4 local)
--   ctrl+shift+n      the local tab, on its notes workspace (Obsidian vault, nvim),
--                     created/focused by `ensure` in the background
-- Each per-machine tab runs a herdr client that knows only that machine, which
-- is what stops it snapping to another one. See wsl/herdr/.config/herdr/scripts/herdr-notes.sh.
local DOMAIN = "WSL:dotfiles-test"
local HERDR_TAB = "~/.config/herdr/scripts/herdr-notes.sh"
local machines = {
	{ title = "backend", cmd = HERDR_TAB .. " remote portalsv2-microservices.devpod" },
	{ title = "mobile", cmd = HERDR_TAB .. " remote portalsv2-practitioner-mobile-app.devpod" },
	{ title = "web", cmd = HERDR_TAB .. " remote portalsv2-frontend-web-apps.devpod" },
	{ title = "local", cmd = HERDR_TAB .. " local", ensure = HERDR_TAB .. " ensure-local" },
}

local function find_tab(mux_window, title)
	for _, tab in ipairs(mux_window:tabs()) do
		if tab:get_title() == title then
			return tab
		end
	end
end

local function goto_tab(window, title, cmd)
	local mux_window = window:mux_window()
	local tab = find_tab(mux_window, title)
	if tab then
		tab:activate()
		return
	end
	tab = mux_window:spawn_tab({
		domain = { DomainName = DOMAIN },
		args = { "bash", "-lc", cmd .. "; exec bash -l" },
	})
	tab:set_title(title)
end

config.keys = {
	{
		key = "R",
		mods = "CTRL|SHIFT",
		action = wezterm.action_callback(function(window, pane)
			goto_tab(window, "all", "herdr")
		end),
	},
	{
		key = "N",
		mods = "CTRL|SHIFT",
		action = wezterm.action_callback(function(window, pane)
			if find_tab(window:mux_window(), "local") then
				-- Local tab already open: show it now and set the notes workspace
				-- up in the background, so the key never waits on herdr.
				wezterm.background_child_process({
					"wsl.exe", "-d", "dotfiles-test", "--", "bash", "-lc", HERDR_TAB .. " ensure",
				})
				goto_tab(window, "local", "")
			else
				goto_tab(window, "local", HERDR_TAB .. " notes")
			end
		end),
	},
	{ key = "UpArrow", mods = "CTRL|SHIFT", action = wezterm.action.IncreaseFontSize },
	{ key = "DownArrow", mods = "CTRL|SHIFT", action = wezterm.action.DecreaseFontSize },
	-- WezTerm's default ctrl+shift+k is ClearScrollback; herdr uses it for previous_workspace.
	{ key = "K", mods = "CTRL|SHIFT", action = wezterm.action.DisableDefaultAssignment },
}

for i, m in ipairs(machines) do
	table.insert(config.keys, {
		-- phys: so it works whatever the keyboard layout does to shift+digit
		key = "phys:" .. i,
		mods = "CTRL|SHIFT",
		action = wezterm.action_callback(function(window, pane)
			if m.ensure and find_tab(window:mux_window(), m.title) then
				-- Tab already open: focus its workspace in the background.
				wezterm.background_child_process({
					"wsl.exe", "-d", "dotfiles-test", "--", "bash", "-lc", m.ensure,
				})
			end
			goto_tab(window, m.title, m.cmd)
		end),
	})
end

-- Start with the "all" tab so ctrl+shift+r finds it instead of making a second.
wezterm.on("gui-startup", function(cmd)
	local tab = wezterm.mux.spawn_window({
		domain = { DomainName = DOMAIN },
		args = { "bash", "-lc", "herdr; exec bash -l" },
	})
	tab:set_title("all")
end)

-- config.leader = {
-- 	key = "Space",
-- 	mods = "CTRL",
-- }
--
-- config.keys = {
-- 	{
-- 		mods = "LEADER",
-- 		key = "x",
-- 		action = act.CloseCurrentPane({ confirm = false }),
-- 	},
-- 	{
-- 		mods = "LEADER",
-- 		key = "w",
-- 		action = act.CloseCurrentTab({ confirm = false }),
-- 	},
-- 	{
-- 		key = "n",
-- 		mods = "LEADER",
-- 		action = wezterm.action_callback(function(window, pane)
-- 			popup_window(window, pane, "cd ~/obsidian-vault && nvim main.md")
-- 	end),
-- 	},
-- 	{
-- 		mods = "LEADER",
-- 		key = "s",
-- 		action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }),
-- 	},
-- 	{
-- 		mods = "LEADER",
-- 		key = "v",
-- 		action = act.SplitVertical({ domain = "CurrentPaneDomain" }),
-- 	},
-- 	{
-- 		mods = "LEADER",
-- 		key = "R",
-- 		action = act.PromptInputLine({
-- 			description = "Enter new workspace name",
-- 			action = wezterm.action_callback(function(window, pane, line)
-- 				if line then
-- 					wezterm.mux.rename_workspace(window:active_workspace(), line)
-- 				end
-- 			end),
-- 		}),
-- 	},
-- 	{
-- 		mods = "LEADER",
-- 		key = "t",
-- 		action = act.SpawnTab("CurrentPaneDomain"),
-- 	},
-- 	{ key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
-- 	{ key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
-- 	{ key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
-- 	{ key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },
-- 	{
-- 		mods = "LEADER",
-- 		key = "r",
-- 		action = act.PromptInputLine({
-- 			description = "Enter new tab name",
-- 			action = wezterm.action_callback(function(window, pane, line)
-- 				if line then
-- 					window:active_tab():set_title(line)
-- 				end
-- 			end),
-- 		}),
-- 	},
-- 	{
-- 		mods = "LEADER",
-- 		key = "d",
-- 		action = wezterm.action_callback(function(window, pane)
-- 			local mux_win = window:mux_window()
-- 			window:perform_action(act.SwitchWorkspaceRelative(-1), pane)
-- 			for _, tab in ipairs(mux_win:tabs()) do
-- 				tab:activate()
-- 				window:perform_action(act.CloseCurrentTab({ confirm = false }), pane)
-- 			end
-- 		end),
-- 	},
-- 	-- Resize mode - press LEADER + arrow to enter, keep pressing to resize
-- 	{
-- 		mods = "LEADER",
-- 		key = "LeftArrow",
-- 		action = act.Multiple({
-- 			act.AdjustPaneSize({ "Left", 5 }),
-- 			act.ActivateKeyTable({ name = "resize_pane", one_shot = false }),
-- 		}),
-- 	},
-- 	{
-- 		mods = "LEADER",
-- 		key = "RightArrow",
-- 		action = act.Multiple({
-- 			act.AdjustPaneSize({ "Right", 5 }),
-- 			act.ActivateKeyTable({ name = "resize_pane", one_shot = false }),
-- 		}),
-- 	},
-- 	{
-- 		mods = "LEADER",
-- 		key = "DownArrow",
-- 		action = act.Multiple({
-- 			act.AdjustPaneSize({ "Down", 5 }),
-- 			act.ActivateKeyTable({ name = "resize_pane", one_shot = false }),
-- 		}),
-- 	},
-- 	{
-- 		mods = "LEADER",
-- 		key = "UpArrow",
-- 		action = act.Multiple({
-- 			act.AdjustPaneSize({ "Up", 5 }),
-- 			act.ActivateKeyTable({ name = "resize_pane", one_shot = false }),
-- 		}),
-- 	},
-- }
--
-- config.key_tables = {
-- 	resize_pane = {
-- 		{ key = "LeftArrow", action = act.AdjustPaneSize({ "Left", 5 }) },
-- 		{ key = "RightArrow", action = act.AdjustPaneSize({ "Right", 5 }) },
-- 		{ key = "DownArrow", action = act.AdjustPaneSize({ "Down", 5 }) },
-- 		{ key = "UpArrow", action = act.AdjustPaneSize({ "Up", 5 }) },
-- 		{ key = "Escape", action = act.PopKeyTable },
-- 		{ key = "Enter", action = act.PopKeyTable },
-- 	},
-- }
--
-- for i = 1, 9 do
-- 	table.insert(config.keys, {
-- 		key = tostring(i),
-- 		mods = "LEADER",
-- 		action = act.ActivateTab(i - 1),
-- 	})
-- end
--
-- --[[
-- local function tab_title(tab_info)
--   local title = tab_info.tab_title
--   if title and #title > 0 then return title end
--   return tab_info.active_pane.title
-- end
--
--[[
============================
Leader Active Indicator
============================
]]
--

return config

