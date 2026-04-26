local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()
local bar = wezterm.plugin.require 'https://github.com/adriankarlen/bar.wezterm'
local resurrect = wezterm.plugin.require 'https://github.com/MLFlexer/resurrect.wezterm'

local function show_toast(window, message)
  if window then
    window:toast_notification('WezTerm', message, nil, 3000)
  end
end

local function save_workspace_state(window)
  resurrect.state_manager.save_state(resurrect.workspace_state.get_workspace_state())
  show_toast(window, 'Workspace state saved')
end

local function restore_state(window, pane)
  resurrect.fuzzy_loader.fuzzy_load(window, pane, function(id)
    local state_type = string.match(id, '^([^/]+)')
    local state_name = string.match(id, '([^/]+)$') or id
    state_name = string.match(state_name, '(.+)%..+$') or state_name

    local opts = {
      relative = true,
      resize_window = false,
      restore_text = false,
      on_pane_restore = resurrect.tab_state.default_on_pane_restore,
    }

    if state_type == 'workspace' then
      local state = resurrect.state_manager.load_state(state_name, 'workspace')
      resurrect.workspace_state.restore_workspace(state, opts)
    elseif state_type == 'window' then
      local state = resurrect.state_manager.load_state(state_name, 'window')
      resurrect.window_state.restore_window(pane:window(), state, opts)
    elseif state_type == 'tab' then
      local state = resurrect.state_manager.load_state(state_name, 'tab')
      resurrect.tab_state.restore_tab(pane:tab(), state, opts)
    end
  end, {
    title = 'Restore State',
    description = 'Pick a saved workspace, window, or tab state',
    fuzzy_description = 'Search saved state: ',
    is_fuzzy = true,
  })
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

bar.apply_to_config(config, {
  position = 'top',
  modules = {
    leader = {
      enabled = false,
    },
    pane = {
      enabled = true,
      color = '#f9e2af',
    },
    workspace = {
      enabled = true,
      color = '#89b4fa',
    },
    username = {
      enabled = false,
    },
    hostname = {
      enabled = false,
    },
    cwd = {
      enabled = true,
      color = '#94e2d5',
    },
    ssh = {
      enabled = true,
      color = '#fab387',
    },
    clock = {
      enabled = true,
      format = '%H:%M',
      color = '#f5c2e7',
    },
  },
})

resurrect.state_manager.set_max_nlines(2000)

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
