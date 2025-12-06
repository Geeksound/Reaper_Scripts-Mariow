--[[
@description Consolidate items (ProTools Alt+Shift+3 style)
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-11-26)
  - Initial release: heal/normalize, consolidate, rename take, cleanup
@provides
  [main] Protools_Edit/Consolidate-(PT AltShift3).lua
@tags editing, consolidate, normalize, takes, (protools-like)
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@about
  # Consolidate Items (ProTools-like)
  Recreates Pro Tools' **Alt+Shift+3** workflow.
--]]

reaper.Undo_BeginBlock()

local startTime, endTime = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
local anyItem = reaper.CountSelectedMediaItems(0) > 0
local anyTrackSelected = reaper.CountSelectedTracks(0) > 0
local timeSelectionExists = endTime > startTime

if anyItem then
  -- 1. Items selected: glue them directly
  reaper.Main_OnCommand(41588, 0) -- Glue Items
elseif timeSelectionExists and anyTrackSelected then
  -- 2. Time selection exists + tracks selected: glue only portion of items on selected tracks
  -- Deselect all items first
  for i = 0, reaper.CountMediaItems(0)-1 do
    reaper.SetMediaItemSelected(reaper.GetMediaItem(0, i), false)
  end
  
  -- Loop over selected tracks
  for t = 0, reaper.CountSelectedTracks(0)-1 do
    local track = reaper.GetSelectedTrack(0, t)
    -- Loop over all items on track
    for i = 0, reaper.CountTrackMediaItems(track)-1 do
      local item = reaper.GetTrackMediaItem(track, i)
      local itemStart = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
      local itemEnd = itemStart + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
      -- Check intersection with time selection
      if itemEnd > startTime and itemStart < endTime then
        reaper.SetMediaItemSelected(item, true)
      end
    end
  end
  
  -- Glue only the selected portions
  reaper.Main_OnCommand(41588, 0) -- Glue Items
else
  -- 3. Nothing selected
  reaper.ShowMessageBox("Make a Selection", "Info", 0)
end

reaper.Undo_EndBlock("Consolidate Items within Time Selection on selected tracks", -1)

