--[[
@description Extend Edit Up (ProTools-like SHIFT+P)
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-11-30)
  - Initial release: extends the active Razor Edit upward to the track above, emulating Pro Tools’ Shift+P behavior
@provides
  [main] Protools_Edit/ExtendEditUp(PT Shift P).lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags editing, razor, selection, arrange, (protools-like)
@about
  # Extend Edit Up (ProTools-like)
  Extends the current Razor Edit area from the selected track to the track above,
  mimicking Pro Tools’ Shift+P behavior for extending an edit selection upward.
  Useful for multi-track editing, grouping-like workflows, and fast vertical edit extension.
--]]

-- Extend Razor Area Up
local function Msg(s) reaper.ShowMessageBox(s, "Razor Extend", 0) end

local function extendRazor(up)
    local track = reaper.GetSelectedTrack(0, 0)
    if not track then return end

    -- Lire la razor area de la piste sélectionnée
    local ok, razor = reaper.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", "", false)
    if not ok or razor == "" then
        Msg("Aucune Razor Area sur la piste sélectionnée.")
        return
    end

    -- Trouver la piste cible
    local idx = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
    local dest = reaper.GetTrack(0, idx - 1 + (up and -1 or 1))
    if not dest then
        Msg("Impossible d'étendre : pas de piste " .. (up and "au-dessus." or "en-dessous."))
        return
    end

    -- Appliquer la même razor area à la piste cible
    reaper.GetSetMediaTrackInfo_String(dest, "P_RAZOREDITS", razor, true)
    reaper.TrackList_AdjustWindows(false)
    reaper.UpdateArrange()
end

reaper.Undo_BeginBlock()
extendRazor(true) -- true = vers la piste au-dessus
reaper.Undo_EndBlock("Extend Razor Area Up", -1)

