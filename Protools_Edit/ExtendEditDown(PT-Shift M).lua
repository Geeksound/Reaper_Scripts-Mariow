--[[
@description Extend Edit Down (ProTools-like SHIFT+M)
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-11-30)
  - Initial release: reliably extends the current Razor Edit down to the next track,
    emulating Pro Tools’ Shift+M vertical edit extension behavior.
@provides
  [main] Protools_Edit/ExtendEditDown(PT Shift M).lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags editing, razor, selection, vertical, arrange, (protools-like)
@about
  # Extend Edit Down (ProTools-like)
  Extends the current Razor Edit from the source track to the track below,
  following Pro Tools' Shift+M shortcut behavior.
  
  The script supports repeated execution:
  each subsequent run adds the Razor Edit to the next track further down,
  enabling rapid vertical multi-track edit extension.
--]]


local SECTION = "Mariow_Scripts"
local KEY = "RazorSourceTrack"

reaper.Undo_BeginBlock()

-- 1) Identifier la piste source
local srcTrack
local stored = reaper.GetExtState(SECTION, KEY)
if stored ~= "" then
    srcTrack = reaper.GetTrack(0, tonumber(stored))
end

-- Sinon, première exécution : prendre la piste sélectionnée
if not srcTrack then
    srcTrack = reaper.GetSelectedTrack(0, 0)
    if not srcTrack then reaper.Undo_EndBlock("No track", -1) return end
    local idx = math.floor(reaper.GetMediaTrackInfo_Value(srcTrack, "IP_TRACKNUMBER")) - 1
    reaper.SetExtState(SECTION, KEY, tostring(idx), false)
end

-- 2) Lire Razor de la source
local ok, razorStr = reaper.GetSetMediaTrackInfo_String(srcTrack, "P_RAZOREDITS", "", false)
if not ok or razorStr == "" then reaper.Undo_EndBlock("No Razor", -1) return end

-- 3) Trouver la dernière piste contenant le Razor (ou juste en dessous de la source)
local lastTrack = srcTrack
for i = 0, reaper.CountTracks(0)-1 do
    local tr = reaper.GetTrack(0, i)
    local _, rz = reaper.GetSetMediaTrackInfo_String(tr, "P_RAZOREDITS", "", false)
    if rz == razorStr then lastTrack = tr end
end

-- 4) Piste du dessous
local lastIdx = math.floor(reaper.GetMediaTrackInfo_Value(lastTrack, "IP_TRACKNUMBER"))
local below = reaper.GetTrack(0, lastIdx)
if not below then reaper.Undo_EndBlock("No track below", -1) return end

-- 5) Copier Razor de la source
reaper.GetSetMediaTrackInfo_String(below, "P_RAZOREDITS", razorStr, true)

reaper.Undo_EndBlock("Extend Razor Down", -1)

