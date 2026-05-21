-- Per-host configuration and shared paths.

local M = {}

local home = os.getenv("HOME")

-- Three host modes:
--   1. yabai + SIP disabled  (personal mac)    → IS_YABAI && SIP_DISABLED
--   2. yabai + SIP enabled   (work mac)        → IS_YABAI && !SIP_DISABLED
--   3. no yabai              (anything else)   → !IS_YABAI
--
-- IS_YABAI is inferred from presence of ~/.yabairc (yabai's own config
-- file — exists by definition on a yabai-managed host).
M.IS_YABAI = hs.fs.attributes(home .. "/.yabairc") ~= nil

-- SIP_DISABLED gates scripting-addition-requiring features (sticky,
-- scratchpads, space --move, sub-layer, opacity, shadow). Programma
-- minimum marker file: `touch ~/.sip_disabled` on a host where SIP
-- is actually off and yabai SA is loaded.
M.SIP_DISABLED = hs.fs.attributes(home .. "/.sip_disabled") ~= nil

-- Convenience: SA features available iff yabai is here AND SIP is off.
M.IS_YABAI_SA = M.IS_YABAI and M.SIP_DISABLED

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
