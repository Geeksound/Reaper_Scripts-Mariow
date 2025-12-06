--[[
@description Extend Edit to Project End (ProTools-like AltShift Return)
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-12-01)
  - If no Razor exists on the selected track, creates one from the edit cursor to the project end
  - If a Razor exists, extends its end to the end of the project
@provides
  [main] Protools_Edit/ExtendEditToEnd(PT AltShift Return).lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags editing, razor, selection, arrange, (protools-like)
@about
  # Extend Edit to Project End (ProTools-like)
  Extends the current Razor Edit area from its existing end point all the way to 
  the end of the project—matching Pro Tools’ Shift+S behavior for extending 
  an edit selection to the end of the session.

  If no Razor Edit exists on the selected track, the script automatically creates
  a new Razor Edit from the edit cursor to the project end, enabling seamless
  ProTools-style workflow even without a prior selection.
--]]

-- Fonction : fin du projet = fin du dernier item

local function getProjectEnd()
    local itemCount = reaper.CountMediaItems(0)
    local lastPos = 0
    for i = 0, itemCount - 1 do
        local it = reaper.GetMediaItem(0, i)
        local pos = reaper.GetMediaItemInfo_Value(it, "D_POSITION")
        local len = reaper.GetMediaItemInfo_Value(it, "D_LENGTH")
        lastPos = math.max(lastPos, pos + len)
    end
    return lastPos
end

reaper.Undo_BeginBlock()

-- Piste sélectionnée
local tr = reaper.GetSelectedTrack(0, 0)
if not tr then
    reaper.Undo_EndBlock("No track selected", -1)
    return
end

local projectEnd = getProjectEnd()

-- Lire Razor existant
local ok, razor = reaper.GetSetMediaTrackInfo_String(tr, "P_RAZOREDITS", "", false)

-- ► Aucun Razor → on en crée un depuis le cursor jusqu'à la fin du projet
if not ok or razor == "" then
    local cursor = reaper.GetCursorPosition()
    local newRazor = string.format("%.20f %.20f \"\"", cursor, projectEnd)
    reaper.GetSetMediaTrackInfo_String(tr, "P_RAZOREDITS", newRazor, true)
    reaper.Undo_EndBlock("Create Razor Area to Project End", -1)
    reaper.UpdateArrange()
    return
end

-- ► Sinon : étendre EXISTING Razor(s) jusqu’à la fin du projet
local parts = {}
for s, e, g in string.gmatch(razor, '(%S+)%s+(%S+)%s+"(.-)"') do
    local startVal = tonumber(s)
    if startVal then
        table.insert(parts, string.format("%.20f %.20f \"%s\"", startVal, projectEnd, g))
    end
end

if #parts > 0 then
    local newRazor = table.concat(parts, " ")
    reaper.GetSetMediaTrackInfo_String(tr, "P_RAZOREDITS", newRazor, true)
end

reaper.Undo_EndBlock("Extend Razor Area to Project End", -1)
reaper.UpdateArrange()

