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

kbd.setGroup("Apps")

-- Common: same on both hosts
kbd.bind(alt, "o", "Obsidian", launch("Obsidian"))
kbd.bind(alt, "w", "Bitwarden", launch("Bitwarden"))
kbd.bind(alt, "s", "Safari", launch("Safari"))

-- alt - r: Obsidian DAR + ctrl+d (today's daily note shortcut).
-- Works on both hosts (no yabai dependency).
kbd.bind(alt, "r", "Obsidian daily note (DAR)", function()
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
  kbd.bind(alt, "g", "Telegram → space sG", function()
    hs.application.launchOrFocus("Telegram")
    yab.cmd({ "space", "--focus", "sG" })
  end)

  -- alt - f: Finder toggle helper
  kbd.bind(alt, "f", "Finder toggle", function() yab.helper("finder-toggle.sh") end)

else
  -- ============================================================
  -- non-yabai launchers (no space focus)
  -- ============================================================

  kbd.bind(alt, "g", "Telegram", launch("Telegram"))
  kbd.bind(alt, "m", "Outlook", launch("Microsoft Outlook"))
  kbd.bind(alt, "f", "Finder", launch("Finder"))

  -- Suggestions (uncomment as needed):
  -- kbd.bind(alt, "c", launch("Calendar"))
  -- kbd.bind(alt, "v", launch("Visual Studio Code"))
  -- kbd.bind(alt, "b", launch("Bear"))
  -- kbd.bind(alt, "t", launch("iTerm"))
end
