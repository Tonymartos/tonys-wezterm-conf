local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()
local bar = wezterm.plugin.require 'https://github.com/adriankarlen/bar.wezterm'
local resurrect = wezterm.plugin.require 'https://github.com/MLFlexer/resurrect.wezterm'

local bar_opts = {
  position = 'bottom',
  max_width = 32,
  padding = {
    left = 1,
    right = 1,
    tabs = {
      left = 0,
      right = 2,
    },
  },
  separator = {
    space = 1,
    left_icon = wezterm.nerdfonts.fa_long_arrow_right,
    right_icon = wezterm.nerdfonts.fa_long_arrow_left,
    field_icon = wezterm.nerdfonts.indent_line,
  },
  modules = {
    tabs = {
      active_tab_fg = 4,
      active_tab_bg = 'transparent',
      inactive_tab_fg = 6,
      inactive_tab_bg = 'transparent',
      new_tab_fg = 2,
      new_tab_bg = 'transparent',
    },
    workspace = {
      enabled = true,
      icon = wezterm.nerdfonts.cod_window,
      color = 8,
    },
    leader = {
      enabled = true,
      icon = wezterm.nerdfonts.oct_rocket,
      color = 2,
    },
    zoom = {
      enabled = false,
      icon = wezterm.nerdfonts.md_fullscreen,
      color = 4,
    },
    pane = {
      enabled = true,
      icon = wezterm.nerdfonts.cod_multiple_windows,
      color = 7,
    },
    username = {
      enabled = true,
      icon = wezterm.nerdfonts.fa_user,
      color = 6,
    },
    hostname = {
      enabled = true,
      icon = wezterm.nerdfonts.cod_server,
      color = 8,
    },
    clock = {
      enabled = true,
      icon = wezterm.nerdfonts.md_calendar_clock,
      format = '%H:%M',
      color = 5,
    },
    cwd = {
      enabled = true,
      icon = wezterm.nerdfonts.oct_file_directory,
      color = 7,
    },
    ssh = {
      enabled = false,
      icon = wezterm.nerdfonts.md_ssh,
      color = 5,
    },
    spotify = {
      enabled = false,
      icon = wezterm.nerdfonts.fa_spotify,
      color = 3,
      max_width = 64,
      throttle = 15,
    },
  },
}

local resurrect_restore_opts = {
  relative = true,
  restore_text = true,
  on_pane_restore = resurrect.tab_state.default_on_pane_restore,
}

local function write_current_workspace_state()
  resurrect.state_manager.write_current_state(wezterm.mux.get_active_workspace(), 'workspace')
end

local function show_toast(window, message)
  if window then
    window:toast_notification('WezTerm', message, nil, 3000)
  end
end

local function save_workspace_state(window)
  resurrect.state_manager.save_state(resurrect.workspace_state.get_workspace_state())
  write_current_workspace_state()
  show_toast(window, 'Workspace state saved')
end

local function restore_state(window, pane)
  resurrect.fuzzy_loader.fuzzy_load(window, pane, function(id)
    local state_type = string.match(id, '^([^/]+)')
    local state_name = string.match(id, '([^/]+)$') or id
    state_name = string.match(state_name, '(.+)%..+$') or state_name

    if state_type == 'workspace' then
      local state = resurrect.state_manager.load_state(state_name, 'workspace')
      resurrect.workspace_state.restore_workspace(state, resurrect_restore_opts)
    elseif state_type == 'window' then
      local state = resurrect.state_manager.load_state(state_name, 'window')
      resurrect.window_state.restore_window(pane:window(), state, resurrect_restore_opts)
    elseif state_type == 'tab' then
      local state = resurrect.state_manager.load_state(state_name, 'tab')
      resurrect.tab_state.restore_tab(pane:tab(), state, resurrect_restore_opts)
    end
  end)
end

local function update_plugins(window)
  wezterm.plugin.update_all()
  show_toast(window, 'Plugins updated. Restart WezTerm to load the latest versions.')
end

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
  "Symbols Nerd Font Mono",
}
config.font_size = 12.5
config.line_height = 1.1
config.cell_width = 1.0
config.window_background_opacity = 0.95
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false
config.initial_rows = 40
config.initial_cols = 120

bar.apply_to_config(config, bar_opts)

resurrect.state_manager.periodic_save()
wezterm.on('gui-startup', resurrect.state_manager.resurrect_on_gui_startup)
wezterm.on('resurrect.state_manager.periodic_save.finished', function()
  write_current_workspace_state()
end)

config.keys = {
  { key = "t", mods = "CTRL", action = act.SpawnTab "CurrentPaneDomain" },
  {
    key = 's',
    mods = 'ALT',
    action = wezterm.action_callback(function(window)
      save_workspace_state(window)
    end),
  },
  {
    key = 'W',
    mods = 'ALT',
    action = resurrect.window_state.save_window_action(),
  },
  {
    key = 'T',
    mods = 'ALT',
    action = resurrect.tab_state.save_tab_action(),
  },
  {
    key = 'r',
    mods = 'ALT',
    action = wezterm.action_callback(function(window, pane)
      restore_state(window, pane)
    end),
  },
  {
    key = 'u',
    mods = 'ALT',
    action = wezterm.action_callback(function(window)
      update_plugins(window)
    end),
  },
}

config.term = "wezterm"
config.default_prog = { "tmux" }
config.scrollback_lines = 5000

return config
