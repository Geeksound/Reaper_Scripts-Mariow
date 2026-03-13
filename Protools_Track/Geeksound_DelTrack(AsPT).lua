--[[
@description Safe Delete Selected Tracks (ProTools-style)
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-11-26)
  - Initial release
  - Deletes selected tracks if empty; asks confirmation if tracks contain items
@provides
  [main] Protools_Track/DelTrack(AsPT).lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags tracks, delete, safe, editing, (protools-like)
@about
  # Safe Delete Tracks
  Deletes selected tracks in Reaper similar to Pro Tools behavior.
  Empty tracks are deleted immediately. Tracks with items prompt
  for user confirmation before deletion.
--]]

local reaper = reaper

-- Begin undo block
reaper.Undo_BeginBlock()

-- Count selected tracks
local sel_tracks = reaper.CountSelectedTracks(0)
if sel_tracks == 0 then
    reaper.ShowMessageBox("No track selected.", "Safe Delete Tracks", 0)
    return
end

-- Loop over selected tracks
for i = sel_tracks-1, 0, -1 do  -- backward loop to avoid index issues
    local track = reaper.GetSelectedTrack(0, i)
    local item_count = reaper.CountTrackMediaItems(track)

    if item_count == 0 then
        -- Delete immediately
        reaper.DeleteTrack(track)
    else
        -- Ask user confirmation
        local _, track_name = reaper.GetTrackName(track)
        local retval = reaper.ShowMessageBox(
            "Track \""..track_name.."\" contains "..item_count.." item(s).\nDo you want to delete it?",
            "Delete Track?",
            4 -- Yes/No
        )
        if retval == 6 then  -- 6 = Yes
            reaper.DeleteTrack(track)
        end
        -- 7 = No → do nothing
    end
end

reaper.Undo_EndBlock("Safe delete tracks ProTools-style", -1)

