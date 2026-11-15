local wezterm = require 'wezterm'
local is_linux = wezterm.target_triple:find('linux') ~= nil

local config = {
	adjust_window_size_when_changing_font_size = false,
	-- color_scheme = 'termnial.sexy',
	color_scheme = 'Catppuccin Mocha',
    -- color_scheme = 'Solarized Dark - Patched',
	enable_tab_bar = false,
	font_size = 13.0,

	-- macos_window_background_blur = 40,
	macos_window_background_blur = 30,
	
	-- window_background_image = '/Users/omerhamerman/Downloads/3840x1080-Wallpaper-041.jpg',
	-- window_background_image_hsb = {
	-- 	brightness = 0.01,
	-- 	hue = 1.0,
	-- 	saturation = 0.5,
	-- },
	-- window_background_opacity = 0.92,
	window_background_opacity = 1.0,
	-- window_background_opacity = 0.78,
	-- window_background_opacity = 0.20,
	keys = {
		{
			key = 'q',
			mods = 'CTRL',
			action = wezterm.action.ToggleFullScreen,
		},
		{
			key = '\'',
			mods = 'CTRL',
			action = wezterm.action.ClearScrollback 'ScrollbackAndViewport',
		},
	},
	mouse_bindings = {
	  -- Ctrl-click will open the link under the mouse cursor
	  {
	    event = { Up = { streak = 1, button = 'Left' } },
	    mods = 'CTRL',
	    action = wezterm.action.OpenLinkAtMouseCursor,
	  },
	},
}

if is_linux then
  config.enable_wayland = true
  config.front_end = "OpenGL"
  config.font = wezterm.font_with_fallback({
    { family = "Hack Nerd Font Mono", weight = "Regular" },
    { family = "JetBrainsMono Nerd Font" },
    { family = "Symbols Nerd Font Mono" },
    { family = "Roboto" },
    { family = "sans-serif" },
  })
  config.window_padding = { left = 0, right = 0, top = 0, bottom = 0 }
else
  config.font = wezterm.font('Hack Nerd Font Mono')
  config.window_decorations = 'RESIZE'
end

return config
