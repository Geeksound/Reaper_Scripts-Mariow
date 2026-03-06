--[[
@description Extend Edit Down (ProTools-like SHIFT+M)
@version 1.1
@author Mariow
@changelog
  v1.1 (2026-03-04)
  - Bug correction
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
-- Extend Razor Area Down (Cumulative Pro Tools-like)

-- STATE verification

local SECTION = "Mariow_Scripts"
local KEY     = "RazorAffectsTrack"

-- Force le mode RazorAffectsTrack à ON si nécessaire
if reaper.GetExtState(SECTION, KEY) ~= "ON" then
    reaper.SetExtState(SECTION, KEY, "ON", false)
end
----------------------


local function Msg(s) reaper.ShowMessageBox(s, "Razor Extend", 0) end

reaper.Undo_BeginBlock()

local selected = reaper.GetSelectedTrack(0, 0)
if not selected then return end

-- Lire Razor de la piste sélectionnée
local ok, razor = reaper.GetSetMediaTrackInfo_String(selected, "P_RAZOREDITS", "", false)
if not ok or razor == "" then
    Msg("PLEASE Link Razor to Tracks with Link-Unlink-RazorToTrack(PT like).lua")
    reaper.Undo_EndBlock("No Razor", -1)
    return
end

-- Trouver la piste la plus basse ayant déjà cette razor
local lastTrack = selected
local selectedIdx = reaper.GetMediaTrackInfo_Value(selected, "IP_TRACKNUMBER")

for i = selectedIdx - 1, reaper.CountTracks(0) - 1 do
    local tr = reaper.GetTrack(0, i)
    local _, rz = reaper.GetSetMediaTrackInfo_String(tr, "P_RAZOREDITS", "", false)
    if rz == razor then
        lastTrack = tr
    else
        break
    end
end

-- Étendre à la piste suivante
local lastIdx = reaper.GetMediaTrackInfo_Value(lastTrack, "IP_TRACKNUMBER")
local dest = reaper.GetTrack(0, lastIdx)
if not dest then
    Msg("Impossible: no track below")
    reaper.Undo_EndBlock("No track below", -1)
    return
end

reaper.GetSetMediaTrackInfo_String(dest, "P_RAZOREDITS", razor, true)
reaper.TrackList_AdjustWindows(false)
reaper.UpdateArrange()

reaper.Undo_EndBlock("Extend Razor Area Down (Cumulative)", -1)

