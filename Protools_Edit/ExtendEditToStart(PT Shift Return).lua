--[[
@description Extend Edit to Project Start (ProTools-like Shift Return)
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-12-01)
  - If no Razor exists on the selected track, creates one from project start to edit cursor
  - If a Razor exists, extends its start to the beginning of the project
@provides
  [main] Protools_Edit/ExtendEditToStart(PT Shift Return).lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags editing, razor, selection, arrange, (protools-like)
@about
  # Extend Edit to Project Start (ProTools-like)
  Extends the active Razor Edit area from its current start point all the way
  to the beginning of the project — mimicking Pro Tools’ Shift+A behavior,
  which extends the current edit selection to the start of the session.
  
  If no Razor Edit is present on the selected track, the script creates
  a new Razor Edit from the project start to the current edit cursor,
  ensuring consistent ProTools-style editing workflow.
--]]


reaper.Undo_BeginBlock()

-- Piste sélectionnée
local tr = reaper.GetSelectedTrack(0, 0)
if not tr then
    reaper.Undo_EndBlock("No track selected", -1)
    return
end

-- Début du projet (toujours 0.0 dans REAPER)
local projectStart = 0.0

-- Lire Razor existant
local ok, razor = reaper.GetSetMediaTrackInfo_String(tr, "P_RAZOREDITS", "", false)

-- ► Aucun Razor → créer depuis 0 jusqu'au curseur
if not ok or razor == "" then
    local cursor = reaper.GetCursorPosition()
    local selStart = math.min(projectStart, cursor)
    local selEnd   = math.max(projectStart, cursor)
    local newRazor = string.format("%.20f %.20f \"\"", selStart, selEnd)

    reaper.GetSetMediaTrackInfo_String(tr, "P_RAZOREDITS", newRazor, true)
    reaper.Undo_EndBlock("Create Razor Area to Project Start", -1)
    reaper.UpdateArrange()
    return
end

-- ► Sinon : Étendre les Razor existants jusqu’au début du projet
local parts = {}
for s, e, g in string.gmatch(razor, '(%S+)%s+(%S+)%s+"(.-)"') do
    local startVal = tonumber(s)
    if startVal then
        table.insert(parts, string.format("%.20f %.20f \"%s\"", projectStart, tonumber(e), g))
    end
end

if #parts > 0 then
    local newRazor = table.concat(parts, " ")
    reaper.GetSetMediaTrackInfo_String(tr, "P_RAZOREDITS", newRazor, true)
end

reaper.Undo_EndBlock("Extend Razor Area to Project Start", -1)
reaper.UpdateArrange()

