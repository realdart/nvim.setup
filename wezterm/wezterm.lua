-- Pull in the wezterm API
local wezterm = require("wezterm")

return {
	color_scheme = "Old World",
	font = wezterm.font("0xProto Nerd Font", { weight = "Regular" }),
	font_size = 11.5,
	enable_tab_bar = true,
	use_fancy_tab_bar = false,
	window_padding = { left = 2, right = 2, top = 1, bottom = 1 },
	window_close_confirmation = "NeverPrompt",
	default_cursor_style = "BlinkingBar",
	animation_fps = 1,
	colors = {
		tab_bar = {
			active_tab = {
				bg_color = "#1a1b26",
				fg_color = "#a9b1d6",
			},
			inactive_tab = {
				bg_color = "#16161e",
				fg_color = "#565f89",
			},
		},
	},
	keys = {
		{ key = "t", mods = "CTRL", action = wezterm.action({ SpawnTab = "CurrentPaneDomain" }) },
		{ key = "w", mods = "CTRL", action = wezterm.action({ CloseCurrentTab = { confirm = true } }) },
	},
}
