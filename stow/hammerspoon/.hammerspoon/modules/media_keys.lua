-- Media keys via hyper+F-row.
--
-- Replaces the Karabiner rule that maps fn+F10..F12 (mute/vol-) etc.
-- on a Mac where Fn behaves as Hyper. Opt-in: enable by uncommenting
-- the require in init.lua.
--
-- Caveat: Hammerspoon CANNOT make caps_lock act as Hyper by itself
-- as cleanly as Karabiner. Keep Karabiner for that piece on hosts
-- where you rely on it. See KARABINER_REPLACEMENT.md.

local kbd = require("modules.keybind")
local hyper = kbd.hyper

local function postSysKey(name)
  return function()
    hs.eventtap.event.newSystemKeyEvent(name, true):post()
    hs.eventtap.event.newSystemKeyEvent(name, false):post()
  end
end

-- Brightness (F1, F2)
kbd.bind(hyper, "f1", postSysKey("BRIGHTNESS_DOWN"))
kbd.bind(hyper, "f2", postSysKey("BRIGHTNESS_UP"))

-- Mission Control (F3)
kbd.bind(hyper, "f3", function()
  hs.spaces.toggleMissionControl()
end)

-- Spotlight (F4 — original Mac default is Spotlight, not Launchpad)
kbd.bind(hyper, "f4", function()
  hs.eventtap.keyStroke({ "cmd" }, "space")
end)

-- Keyboard backlight (F5, F6)
kbd.bind(hyper, "f5", postSysKey("ILLUMINATION_DOWN"))
kbd.bind(hyper, "f6", postSysKey("ILLUMINATION_UP"))

-- Media playback (F7, F8, F9)
kbd.bind(hyper, "f7", postSysKey("PREVIOUS"))
kbd.bind(hyper, "f8", postSysKey("PLAY"))
kbd.bind(hyper, "f9", postSysKey("NEXT"))

-- Volume (F10, F11, F12)
kbd.bind(hyper, "f10", postSysKey("MUTE"))
kbd.bind(hyper, "f11", postSysKey("SOUND_DOWN"))
kbd.bind(hyper, "f12", postSysKey("SOUND_UP"))
