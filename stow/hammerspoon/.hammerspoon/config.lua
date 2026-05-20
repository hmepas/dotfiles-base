-- Per-host configuration and shared paths.

local M = {}

local home = os.getenv("HOME")

-- Marker file. `touch ~/.yabairc` on yabai-managed mac to enable
-- yabai-specific bindings. Lives outside ~/.hammerspoon so stow does
-- not see it.
M.IS_YABAI = hs.fs.attributes(home .. "/.yabairc") ~= nil

-- yabai binary
M.YABAI_BIN = "/opt/homebrew/bin/yabai"
if not hs.fs.attributes(M.YABAI_BIN) then
  M.YABAI_BIN = "/usr/local/bin/yabai"
end

-- Helper script roots (yabai mac only)
M.YABAI_HELPERS = home .. "/.config/yabai"
M.SKHD_SCRIPTS  = home .. "/.config/skhd/applescripts"

-- simple-bar mode indicator
M.SIMPLE_BAR_REFRESH = "http://localhost:7776/skhd/mode/refresh"
M.YABAI_MODE_SCRIPT  = M.YABAI_HELPERS
  .. "/ubersicht-widgets/simple-bar/lib/scripts/yabai-set-mode-server.sh"

return M
