local wezterm = require("wezterm")

return {
    -- default_prog = { "ubuntu" },
    font = wezterm.font("JetBrainsMono NFM"),
    font_size = 12.0,

    adjust_window_size_when_changing_font_size = false,
    color_scheme = 'Catppuccin Mocha',
    enable_tab_bar = false,

    window_background_opacity = 1.0,
    -- Default Windows titlebar and resize decorations
    window_decorations = 'TITLE | RESIZE',
    mouse_bindings = {
      -- Ctrl-click will open the link under the mouse cursor
      {
        event = { Up = { streak = 1, button = 'Left' } },
        mods = 'CTRL',
        action = wezterm.action.OpenLinkAtMouseCursor,
      },
    },
}
