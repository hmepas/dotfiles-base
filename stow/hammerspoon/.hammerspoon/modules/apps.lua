-- Application launchers.
--
-- yabai mac: open + switch to associated named space.
-- non-yabai mac: just open the app. Different bindings where the
-- yabai key was reserved for space focus (alt-m, alt-c, alt-v, alt-b,
-- alt-t — currently empty on non-yabai, opt-in below).

local cfg = require("config")
local kbd = require("modules.keybind")
local yab = require("modules.yabai")

local alt = kbd.alt
local alt_shift = kbd.alt_shift

local function launch(app)
  return function() hs.application.launchOrFocus(app) end
end

-- Common: same on both hosts
kbd.bind(alt, "o", launch("Obsidian"))
kbd.bind(alt, "w", launch("Bitwarden"))
kbd.bind(alt, "s", launch("Safari"))

-- alt - r: Obsidian DAR + ctrl+d (today's daily note shortcut).
-- Works on both hosts (no yabai dependency).
kbd.bind(alt, "r", function()
  hs.execute("open 'obsidian://open?vault=zk&file=SelfTracking/1.Daily%20Notes/DAR%202026%20WB%20and%20my%20own%20projects'")
  hs.timer.doAfter(0.5, function()
    hs.eventtap.keyStroke({ "ctrl" }, "d")
  end)
end)

if cfg.IS_YABAI then
  -- ============================================================
  -- yabai-only launchers (open + focus space)
  -- ============================================================

  -- alt - g: Telegram + focus sG
  kbd.bind(alt, "g", function()
    hs.application.launchOrFocus("Telegram")
    yab.cmd({ "space", "--focus", "sG" })
  end)

  -- alt - f: Finder toggle helper
  kbd.bind(alt, "f", function() yab.helper("finder-toggle.sh") end)

else
  -- ============================================================
  -- non-yabai launchers (no space focus)
  -- ============================================================

  kbd.bind(alt, "g", launch("Telegram"))
  kbd.bind(alt, "m", launch("Microsoft Outlook"))
  kbd.bind(alt, "f", launch("Finder"))

  -- Suggestions (uncomment as needed):
  -- kbd.bind(alt, "c", launch("Calendar"))
  -- kbd.bind(alt, "v", launch("Visual Studio Code"))
  -- kbd.bind(alt, "b", launch("Bear"))
  -- kbd.bind(alt, "t", launch("iTerm"))
end
