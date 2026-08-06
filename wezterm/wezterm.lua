-- SHIFT+CTRL+L = Debug Mode
-- Pull in the wezterm API
local wezterm = require("wezterm")
local act = wezterm.action
local mux = wezterm.mux

-- Helper function: Extract shortened path from full directory path
-- Shows last N components with ".." prefix if truncated
-- Example: /Users/juri/Documents/projects/monorepo/apps/api (3) -> ..monorepo/apps/api
local function get_shortened_path(path, max_components)
	if not path or path == "" then
		return "~"
	end

	-- Handle home directory
	local home = os.getenv("HOME")
	if path == home then
		return "~"
	end

	-- Replace home with ~ for shorter display
	if home and path:sub(1, #home) == home then
		path = "~" .. path:sub(#home + 1)
	end

	-- Split path into components
	local components = {}
	for part in string.gmatch(path, "[^/]+") do
		table.insert(components, part)
	end

	-- If path has fewer components than max, return as-is
	if #components <= max_components then
		return path
	end

	-- Extract last N components
	local result = {}
	for i = #components - max_components + 1, #components do
		table.insert(result, components[i])
	end

	-- Join with ".." prefix to indicate truncation
	return ".." .. table.concat(result, "/")
end

wezterm.on("gui-startup", function()
	local home = os.getenv("HOME")
	local react_tab, react_pane, react_window = mux.spawn_window({
		cwd = home .. "/Documents/projects/hains/hains_docker/dienstplaner/",
		workspace = "REACT",
	})

	react_window:gui_window():maximize()
	react_tab:set_title("REACT")

	local ws_api_tab, ws_api_pane, ws_api_window = mux.spawn_window({
		cwd = home .. "/Documents/projects/hains/hains_docker/HAINS-api/",
		workspace = "API",
	})
	ws_api_tab:set_title("API")
	ws_api_tab:activate()
	ws_api_pane:activate()

	local ws_joomla_tab, ws_joomla_pane, ws_joomla_window = mux.spawn_window({
		cwd = home .. "/Documents/projects/hains/hains_docker/hains_joomla/joomla/hains",
		workspace = "JOOMLA",
	})

	local ws_docker_tab, ws_docker_pane, ws_docker_window = mux.spawn_window({
		cwd = home .. "/Documents/projects/hains/hains_docker/",
		workspace = "DOCKER",
	})
	ws_docker_tab:set_title("DOCKER")

	local ws_server_tab, ws_server_pane, ws_server_window = mux.spawn_window({
		cwd = home,
		workspace = "SERVER",
	})

	local ws_dev_tab, ws_dev_pane, ws_dev_window = mux.spawn_window({
		cwd = home .. "/Documents/dev/",
		workspace = "DEV",
	})
	ws_dev_tab:set_title("DEV")

	local ws_monorepo_tab, ws_monorepo_pane, ws_monorepo_window = mux.spawn_window({
		cwd = home .. "/Documents/projects/hains/hains_docker/monorepo/",
		workspace = "MONOREPO",
	})
	ws_monorepo_tab:set_title("MONOREPO")

	local ws_config_tab, ws_config_pane, ws_config_window = mux.spawn_window({
		cwd = home .. "/.config/",
		workspace = "CONFIG",
	})
	ws_config_tab:set_title("CONFIG")

	ws_monorepo_tab:activate()

	local ws_api_tab2 = ws_api_window:spawn_tab({})
	ws_api_tab2:set_title("Tab2")

	mux.set_active_workspace("MONOREPO")
end)

-- Status bar: zoom indicator (left) + CPU / RAM / clock (right)
local last_stats_time = 0
local cached_stats = "CPU:-- RAM:--"

wezterm.on("update-status", function(window, pane)
	-- Left: zoom indicator
	local zoom_status = ""
	local tab = pane:tab()
	if tab then
		local panes = tab:panes_with_info()
		for _, p in ipairs(panes) do
			if p.is_active and p.is_zoomed then
				zoom_status = " 🔍 PANE_ZOOMED "
				break
			end
		end
	end

	window:set_left_status(wezterm.format({
		{ Background = { Color = "#1b1e28" } },
		{ Foreground = { Color = "#eb6f92" } },
		{ Attribute = { Intensity = "Normal" } },
		{ Text = zoom_status },
	}))

	-- Right: CPU + RAM (refreshed every 5 s) + clock
	local now = os.time()
	if now - last_stats_time >= 5 then
		last_stats_time = now

		-- CPU: two samples, use second (first is since-boot average; also avoids sh/grep overhead)
		local cpu_str = "CPU:??"
		local cpu_ok, cpu_out = wezterm.run_child_process({ "top", "-l", "2", "-n", "0" })
		if cpu_ok then
			local last_idle
			for v in cpu_out:gmatch("(%d+%.%d+)%% idle") do
				last_idle = tonumber(v)
			end
			if last_idle then
				cpu_str = string.format("CPU:%d%%", math.floor(100 - last_idle))
			end
		end

		-- RAM: matches Activity Monitor "Memory Used" = anonymous + wired + compressed
		local mem_str = "RAM:??"
		local mem_ok, mem_out = wezterm.run_child_process({ "vm_stat" })
		local tot_ok, tot_out = wezterm.run_child_process({ "sysctl", "-n", "hw.memsize" })
		if mem_ok and tot_ok then
			local page_size = tonumber(mem_out:match("page size of (%d+) bytes")) or 16384
			local anonymous = tonumber(mem_out:match("Anonymous pages:%s+(%d+)%.?")) or 0
			local wired = tonumber(mem_out:match("Pages wired down:%s+(%d+)%.?"))
			local compressed = tonumber(mem_out:match("Pages occupied by compressor:%s+(%d+)%.?")) or 0
			local total_bytes = tonumber(tot_out:match("%d+"))
			if anonymous and wired and total_bytes then
				local used_gb = (anonymous + wired + compressed) * page_size / 1073741824
				local total_gb = total_bytes / 1073741824
				mem_str = string.format("RAM:%.1f/%.0fG", used_gb, total_gb)
			end
		end

		cached_stats = cpu_str .. "  " .. mem_str
	end

	window:set_right_status(wezterm.format({
		{ Background = { Color = "#1b1e28" } },
		{ Foreground = { Color = "#a6accd" } },
		{ Text = "  " .. cached_stats .. "  " .. wezterm.strftime("%H:%M") .. "  " },
	}))
end)

-- Custom tab title formatter
wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
	local bar_bg = "#1b1e28"
	local active_bg = "#2a2d3e"
	local active_fg = "#c4c7da"
	local inactive_fg = hover and "#6b7194" or "#2e3250"

	-- Resolve title: explicit name wins, else shortened cwd
	local title = "~"
	if tab.tab_title and #tab.tab_title > 0 then
		title = tab.tab_title
	else
		local pane = tab.active_pane
		local cwd_uri = pane and pane.current_working_dir
		if cwd_uri then
			local cwd_path
			if type(cwd_uri) == "userdata" then
				cwd_path = cwd_uri.file_path
			elseif type(cwd_uri) == "string" then
				cwd_path = cwd_uri:gsub("file://[^/]*", "")
			end
			if cwd_path and cwd_path ~= "" then
				title = get_shortened_path(cwd_path, 3):upper()
			end
		end
	end

	if tab.is_active then
		return {
			{ Background = { Color = bar_bg } },
			{ Foreground = { Color = active_bg } },
			{ Text = wezterm.nerdfonts.pl_right_hard_divider },
			{ Background = { Color = active_bg } },
			{ Foreground = { Color = active_fg } },
			{ Text = " " .. title .. " " },
			{ Background = { Color = bar_bg } },
			{ Foreground = { Color = active_bg } },
			{ Text = wezterm.nerdfonts.pl_left_hard_divider },
		}
	else
		return {
			{ Background = { Color = bar_bg } },
			{ Foreground = { Color = inactive_fg } },
			{ Text = "  " .. title .. "  " },
		}
	end
end)

-- Main config
local config = {}

if wezterm.config_builder then
	config = wezterm.config_builder()
end

config.use_fancy_tab_bar = false
config.audible_bell = "Disabled"
-- config.debug_key_events = true
config.send_composed_key_when_left_alt_is_pressed = true
config.send_composed_key_when_right_alt_is_pressed = true

config.window_padding = {
	left = 0,
	right = 0,
	top = 11,
	bottom = 0,
}

config.enable_scroll_bar = true
config.scrollback_lines = 70000

-- config.font = wezterm.font("JetBrainsMono Nerd Font", { italic = true })
config.font = wezterm.font("Maple Mono NF", { italic = true })
config.font_size = 17.0
config.adjust_window_size_when_changing_font_size = false
config.color_scheme = "Rosé Pine (base16)"
-- config.color_scheme = "lume"
config.max_fps = 120

config.window_frame = {
	-- font = wezterm.font("JetBrainsMono Nerd Font"),
	font = wezterm.font("Maple Mono NF"),
	font_size = 16.0,
}

config.colors = {
	tab_bar = {
		background = "#1b1e28",
		active_tab = { bg_color = "#2a2d3e", fg_color = "#c4c7da" },
		inactive_tab = { bg_color = "#1b1e28", fg_color = "#2e3250" },
		inactive_tab_hover = { bg_color = "#1b1e28", fg_color = "#6b7194" },
		new_tab = { bg_color = "#1b1e28", fg_color = "#6b7194" },
		new_tab_hover = { bg_color = "#1b1e28", fg_color = "#a6accd" },
	},
}

config.window_background_opacity = 1
config.inactive_pane_hsb = { brightness = 0.90 }

config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 2044 }

config.keys = {
	{ key = "k", mods = "CMD", action = act.ClearScrollback("ScrollbackAndViewport") },
	{ key = "=", mods = "CTRL", action = act.ResetFontSize },
	{ key = "|", mods = "LEADER|SHIFT", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "_", mods = "LEADER|SHIFT", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "LeftArrow", mods = "SHIFT", action = act.AdjustPaneSize({ "Left", 3 }) },
	{ key = "DownArrow", mods = "SHIFT", action = act.AdjustPaneSize({ "Down", 3 }) },
	{ key = "UpArrow", mods = "SHIFT", action = act.AdjustPaneSize({ "Up", 3 }) },
	{ key = "RightArrow", mods = "SHIFT", action = act.AdjustPaneSize({ "Right", 3 }) },
	{ key = "0", mods = "LEADER", action = act.PaneSelect({ alphabet = "1234567890" }) },
	{ key = "UpArrow", mods = "ALT", action = act.ScrollByLine(-3) },
	{ key = "DownArrow", mods = "ALT", action = act.ScrollByLine(3) },
	{ key = "UpArrow", mods = "ALT|SHIFT", action = act.ScrollByLine(-24) },
	{ key = "DownArrow", mods = "ALT|SHIFT", action = act.ScrollByLine(24) },
	{ key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
	{ key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },
	{ key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
	{ key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
	{ key = "x", mods = "LEADER", action = wezterm.action.CloseCurrentPane({ confirm = true }) },
	{ key = "f", mods = "LEADER", action = wezterm.action.ToggleFullScreen },
	{ key = "=", mods = "LEADER", action = wezterm.action.TogglePaneZoomState },
	{
		key = "s",
		mods = "LEADER",
		action = act.ShowLauncherArgs({ flags = "WORKSPACES" }),
	},
	{
		key = "w",
		mods = "LEADER",
		action = act.PromptInputLine({
			description = wezterm.format({
				{ Attribute = { Intensity = "Bold" } },
				{ Foreground = { AnsiColor = "Fuchsia" } },
				{ Text = "Enter name for new workspace" },
			}),
			action = wezterm.action_callback(function(window, pane, line)
				if line then
					window:perform_action(act.SwitchToWorkspace({ name = line }), pane)
				end
			end),
		}),
	},

	-- Pane swap: Leader + p, then type the number of the pane to swap with
	{ key = "p", mods = "LEADER", action = act.PaneSelect({ mode = "SwapWithActive" }) },
	{
		key = "Return",
		mods = "SHIFT",
		action = wezterm.action.SendString("\x1b\n"),
	},
}

-- Leader+Number tab switch
for i = 1, 8 do
	table.insert(config.keys, {
		key = tostring(i),
		mods = "LEADER",
		action = act.ActivateTab(i - 1),
	})
end

-- Force Option+A to send <M-a> (ESC + a) for Neovim
table.insert(config.keys, {
	key = "a",
	mods = "ALT",
	action = wezterm.action.SendString("\x1ba"),
})

return config
