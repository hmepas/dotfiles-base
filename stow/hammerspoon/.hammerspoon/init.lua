-- Hammerspoon entrypoint. Load modules in order.

-- Enable CLI (`hs -c`) and AppleScript reload from outside.
require("hs.ipc")
hs.allowAppleScript(true)

local cfg = require("config")

require("modules.system")
require("modules.apps")
require("modules.spaces")
require("modules.windows")
require("modules.modes.app_launch")

if cfg.IS_YABAI then
  require("modules.modes.scratchpad")
  require("modules.modes.service")
end

-- Optional: replace Karabiner Fn-row media handling on non-yabai mac.
-- Uncomment to enable. See KARABINER_REPLACEMENT.md.
-- require("modules.media_keys")

hs.alert.show("Hammerspoon loaded" .. (cfg.IS_YABAI and " [yabai]" or " [no-yabai]"))
