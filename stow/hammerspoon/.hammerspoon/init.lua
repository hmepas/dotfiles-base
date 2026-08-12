-- Hammerspoon entrypoint. Load modules in order.

-- Enable CLI (`hs -c`) and AppleScript reload from outside.
require("hs.ipc")
hs.allowAppleScript(true)

local cfg = require("config")

require("modules.system")
require("modules.input_sources")
require("modules.apps")
require("modules.spaces")
require("modules.windows")
require("modules.modes.app_launch")
require("modules.browser_guard")

if cfg.IS_YABAI then
  require("modules.modes.service")
  -- Scratchpads are SA-only (sub-layer, --scratchpad, --toggle by LABEL).
  if cfg.SIP_DISABLED then
    require("modules.modes.scratchpad")
  end
end

-- Optional: replace Karabiner Fn-row media handling on non-yabai mac.
-- Uncomment to enable. See KARABINER_REPLACEMENT.md.
-- require("modules.media_keys")

local mode
if cfg.IS_YABAI_SA then     mode = " [yabai+SA]"
elseif cfg.IS_YABAI then    mode = " [yabai no-SA]"
else                        mode = " [no-yabai]" end
hs.alert.show("Hammerspoon loaded" .. mode)
