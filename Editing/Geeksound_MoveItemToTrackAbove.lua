--[[
@description Move selected item to track above
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-11-10)
  - Initial release
@provides
  [main] Editing/Mariow-MoveItemToTrackAbove.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags items, tracks, editing
@about
  # Move selected item to track above
  Moves the first selected media item to the track directly above it (if it exists).
  Useful for quickly rearranging items between adjacent tracks.
--]]

reaper.Undo_BeginBlock()

-- Get the first selected item
local item = reaper.GetSelectedMediaItem(0, 0)
if not item then
  reaper.ShowMessageBox("No item selected.", "Error", 0)
  return
end

-- Get the item's current track
local track = reaper.GetMediaItem_Track(item)
local trackIndex = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER") - 1

-- If it's already on the first track, it can't move up
if trackIndex == 0 then
  reaper.ShowMessageBox("Cannot move up: already on the first track.", "Info", 0)
  return
end

-- Get the track above
local aboveTrack = reaper.GetTrack(0, trackIndex - 1)

-- Move the item to the track above
reaper.MoveMediaItemToTrack(item, aboveTrack)

reaper.UpdateArrange()
reaper.Undo_EndBlock("Move selected item to track above", -1)

