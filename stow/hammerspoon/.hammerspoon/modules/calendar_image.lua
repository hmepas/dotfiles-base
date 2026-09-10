-- 2026 calendar image as an hs.canvas.
-- alt-q shows it while held; app-launch q toggles a persistent, draggable
-- copy (esc or the same chord closes it).

local kbd = require("modules.keybind")

local M = {}

local IMAGE = (os.getenv("HOME") or "") .. "/Yandex.Disk.localized/2026_calendar.png"

local function imageOrAlert()
  local img = hs.fs.attributes(IMAGE) and hs.image.imageFromPath(IMAGE)
  if not img then hs.alert.show("Calendar image missing: " .. IMAGE) end
  return img
end

-- Image at 1:1, shrunk proportionally to fit the screen, centered.
local function fittedFrame(img, screen)
  local size = img:size()
  local sf = screen:frame()
  local scale = math.min(1, sf.w / size.w, sf.h / size.h)
  local w, h = size.w * scale, size.h * scale
  return hs.geometry.rect(sf.x + (sf.w - w) / 2, sf.y + (sf.h - h) / 2, w, h)
end

local function newCanvas(level)
  local img = imageOrAlert()
  if not img then return end
  local c = hs.canvas.new(fittedFrame(img, hs.screen.mainScreen()))
  c[1] = { type = "image", image = img, imageScaling = "scaleProportionally" }
  c:level(level)
  return c
end

-- ---------------------------------------------------------------- hold

local overlay

local function hideOverlay()
  if overlay then overlay:delete(); overlay = nil end
end

local function showOverlay()
  hideOverlay()
  overlay = newCanvas(hs.canvas.windowLevels.overlay)
  if overlay then overlay:show() end
end

-- ---------------------------------------------------------------- persistent

local persistent, escHotkey, dragTap

local function stopDrag()
  if dragTap then dragTap:stop(); dragTap = nil end
end

local function closePersistent()
  stopDrag()
  if persistent then persistent:delete(); persistent = nil end
  if escHotkey then escHotkey:delete(); escHotkey = nil end
end

-- Drag by mouse. The canvas only reports mouseDown/mouseUp (no dragged
-- events), so follow the pointer with an eventtap for the drag's duration.
local function makeDraggable(c)
  local types = hs.eventtap.event.types
  c:canvasMouseEvents(true, false, false, false)
  c:mouseCallback(function(_, event, _, x, y)
    if event ~= "mouseDown" then return end
    stopDrag()
    dragTap = hs.eventtap.new({ types.leftMouseDragged, types.leftMouseUp }, function(e)
      if e:getType() == types.leftMouseUp then
        stopDrag()
      else
        local p = e:location()
        c:topLeft({ x = p.x - x, y = p.y - y })
      end
      return false
    end):start()
  end)
end

function M.togglePersistent()
  if persistent then closePersistent(); return end
  persistent = newCanvas(hs.canvas.windowLevels.floating)
  if not persistent then return end
  makeDraggable(persistent)
  persistent:show()
  escHotkey = hs.hotkey.bind({}, "escape", closePersistent)
end

kbd.setGroup("Apps")
kbd.bind(kbd.alt, "q", "Calendar image (hold)", showOverlay, hideOverlay)

return M
