local wezterm = require 'wezterm'

return {
  default_prog = { "tmux" },
  -- Tema
  color_scheme = "Catppuccin Mocha", -- Puedes cambiarlo por el que quieras
  font = wezterm.font_with_fallback {
    "JetBrainsMono Nerd Font",
    "FiraCode Nerd Font",
  },
  font_size = 12.5,
  line_height = 1.1,
  cell_width = 1.0,

  -- Transparencia
  window_background_opacity = 0.95,

  -- Apariencia de pestañas
  enable_tab_bar = true,
  hide_tab_bar_if_only_one_tab = true,

  -- Tamaño inicial de la ventana
  initial_rows = 40,
  initial_cols = 120,

  -- Atajos personalizados (opcional)
  keys = {
    -- Abrir nueva pestaña con Ctrl + t
    {
      key = "t",
      mods = "CTRL",
      action = wezterm.action.SpawnTab "CurrentPaneDomain",
    },
  },

  -- Integración con tmux y Neovim (TrueColor)
  term = "wezterm", -- Importante para que Neovim lo detecte bien

  -- Scrollback largo (útil para logs o cosas largas en tmux)
  scrollback_lines = 5000,
}
