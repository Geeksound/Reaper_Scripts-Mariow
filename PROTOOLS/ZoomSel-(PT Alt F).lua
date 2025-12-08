--[[
@description Zoom to selected item(s) or time selection (ProTools-like)
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-11-26)
  - Initial release: zooms to selected items or to time selection if no items, emulating Pro Tools behavior
@provides
  [main] PROTOOLS/ZoomSel-(PT Alt F).lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags navigation, zoom, items, time selection, (protools-like)
@about
  # Zoom-Clip (ProTools-like)
  Zooms the arrange view to the selected item(s) if any are selected,
  or to the time selection if no items are selected,
  mimicking Pro Tools' clip zoom behavior.
--]]

reaper.Undo_BeginBlock()

-- Vérifier si au moins un item est sélectionné
local itemCount = reaper.CountSelectedMediaItems(0)
local ts_start, ts_end = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)

if itemCount > 0 then
    -- Items sélectionnés → exécuter le script normal
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_SAFETIMESEL"), 0)
    reaper.Main_OnCommand(40031, 0)
    reaper.Main_OnCommand(40635, 0)
elseif ts_end > ts_start then
    -- Aucun item sélectionné mais time selection existe → zoom sur la time selection
    reaper.Main_OnCommand(40031, 0)
else
    -- Aucun item et pas de time selection → ne rien faire
end

reaper.Undo_EndBlock("Zoom-Clip (PT) conditional", -1)

