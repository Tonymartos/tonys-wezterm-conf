local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

config.alternate_buffer_wheel_scroll_speed = 0

-- Enable scroll bar 
config.enable_scroll_bar = true

-- Scrolls mouse 
config.mouse_bindings = {
  {
    event = { Down = { streak = 1, button = { WheelUp = 1 } } },
    mods = "NONE",
    action = act.ScrollByCurrentEventWheelDelta,
  },
  {
    event = { Down = { streak = 1, button = { WheelDown = 1 } } },
    mods = "NONE",
    action = act.ScrollByCurrentEventWheelDelta,
  },
}

config.color_scheme = "Catppuccin Mocha"
config.font = wezterm.font_with_fallback {
  "JetBrainsMono Nerd Font",
  "FiraCode Nerd Font",
}
config.font_size = 12.5
config.line_height = 1.1
config.cell_width = 1.0
config.window_background_opacity = 0.95
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true
config.initial_rows = 40
config.initial_cols = 120

config.keys = {
  { key = "t", mods = "CTRL", action = act.SpawnTab "CurrentPaneDomain" },
}

config.term = "wezterm"
config.default_prog = { "tmux" }
config.scrollback_lines = 5000

return config
