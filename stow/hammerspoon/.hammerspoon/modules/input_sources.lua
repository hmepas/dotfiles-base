-- Input source switching.
--
-- Replaces patched Kawa behavior:
--   cmd-space  : toggle English/Russian, or leave Chinese back to previous layout
--   ctrl-cmd-c : switch to Simplified Chinese, remembering previous English/Russian

local kbd = require("modules.keybind")

local M = {}

local EN_LAYOUT = "ABC"
local RU_LAYOUT = "Russian – PC"
local ZH_METHOD = "Pinyin – Simplified"
local ZH_SOURCE_ID = "com.apple.inputmethod.SCIM.ITABC"

local previousNonChinese = EN_LAYOUT

local function currentLayout()
  return hs.keycodes.currentLayout()
end

local function currentMethod()
  return hs.keycodes.currentMethod()
end

local function currentSourceID()
  return hs.keycodes.currentSourceID()
end

local function isChinese()
  return currentMethod() == ZH_METHOD or currentSourceID() == ZH_SOURCE_ID
end

local function isKnownNonChineseLayout(layout)
  return layout == EN_LAYOUT or layout == RU_LAYOUT
end

local function rememberCurrentNonChinese()
  if not isChinese() then
    local layout = currentLayout()
    if isKnownNonChineseLayout(layout) then
      previousNonChinese = layout
    end
  end
end

local function setLayout(layout)
  hs.keycodes.setLayout(layout)
  if isKnownNonChineseLayout(layout) then
    previousNonChinese = layout
  end
end

local function setChinese()
  rememberCurrentNonChinese()
  hs.keycodes.setMethod(ZH_METHOD)
end

local function toggleEnglishRussianOrLeaveChinese()
  if isChinese() then
    setLayout(previousNonChinese or EN_LAYOUT)
    return
  end

  local layout = currentLayout()
  if layout == RU_LAYOUT then
    setLayout(EN_LAYOUT)
  else
    -- ABC, unknown layouts, and nil all go to Russian.
    setLayout(RU_LAYOUT)
  end
end

-- Keep state correct if input source is changed outside these hotkeys.
hs.keycodes.inputSourceChanged(function()
  rememberCurrentNonChinese()
end)

kbd.bind({ "cmd" }, "space", toggleEnglishRussianOrLeaveChinese)
kbd.bind({ "ctrl", "cmd" }, "c", setChinese)

M.toggleEnglishRussianOrLeaveChinese = toggleEnglishRussianOrLeaveChinese
M.setChinese = setChinese

return M
