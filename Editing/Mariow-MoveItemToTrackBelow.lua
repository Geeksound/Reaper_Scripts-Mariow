--[[
@description Move selected item to track below (create new one if needed, with unique name)
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-11-10)
  - Initial release
@provides
  [main] Editing/Mariow-MoveItemToTrackBelow.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags items, tracks, editing, creation
@about
  # Move selected item to track below (auto-create)
  Moves the first selected media item to the track directly below it.
  If no track exists below, the script creates a new one and names it after the item's active take.
  If the name already exists, it automatically increments the name to keep it unique.
--]]

reaper.Undo_BeginBlock()

-- Function: check if a track name already exists
local function TrackNameExists(name)
  local trackCount = reaper.CountTracks(0)
  for i = 0, trackCount - 1 do
    local tr = reaper.GetTrack(0, i)
    local _, trName = reaper.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
    if trName == name then
      return true
    end
  end
  return false
end

-- Function: generate a unique track name
-- Example: "Guitar", "Guitar (2)", "Guitar (3)", etc.
local function GetUniqueTrackName(baseName)
  local newName = baseName
  local count = 2
  while TrackNameExists(newName) do
    newName = string.format("%s (%d)", baseName, count)
    count = count + 1
  end
  return newName
end

-- Get the first selected item
local item = reaper.GetSelectedMediaItem(0, 0)
if not item then
  reaper.ShowMessageBox("No item selected.", "Error", 0)
  return
end

-- Get the item's current track
local track = reaper.GetMediaItem_Track(item)
local trackIndex = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER") - 1

-- Get the track below (if it exists)
local belowTrack = reaper.GetTrack(0, trackIndex + 1)

-- If the track below doesn’t exist, create a new one
if not belowTrack then
  reaper.InsertTrackAtIndex(trackIndex + 1, true)
  reaper.TrackList_AdjustWindows(false)

  belowTrack = reaper.GetTrack(0, trackIndex + 1)

  -- Name the new track after the active take name (with increment if needed)
  local take = reaper.GetActiveTake(item)
  local takeName = take and reaper.GetTakeName(take) or "New Track"
  local uniqueName = GetUniqueTrackName(takeName)
  reaper.GetSetMediaTrackInfo_String(belowTrack, "P_NAME", uniqueName, true)
end

-- Move the item to the track below
reaper.MoveMediaItemToTrack(item, belowTrack)

reaper.UpdateArrange()
reaper.Undo_EndBlock("Move selected item to track below (create if needed, unique name)", -1)

