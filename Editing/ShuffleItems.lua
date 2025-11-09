--[[
@description Shuffle Items on One Track (Pro Tools Style)
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-11-09)
  - Initial release
@provides
  [main] Editing/shuffleItems.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags items, track, editing, arrange
@about
  # shuffle-items-on-one-track
  Reorganizes the selected items (or all items on the track) without gaps or overlaps,
  similar to the shuffle behavior in Pro Tools.
  This script was developed with the help of GitHub Copilot.
--]]

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

-- Check that at least one item is selected
local sel_count = reaper.CountSelectedMediaItems(0)
if sel_count == 0 then
  reaper.ShowMessageBox("No item selected.", "Shuffle Items", 0)
  reaper.PreventUIRefresh(-1)
  reaper.Undo_EndBlock("Shuffle Items - Nothing Selected", -1)
  return
end

-- Get the selected items
local items = {}
for i = 0, sel_count - 1 do
  local item = reaper.GetSelectedMediaItem(0, i)
  table.insert(items, item)
end

-- Ensure all items are on the same track
local track = reaper.GetMediaItem_Track(items[1])
for _, it in ipairs(items) do
  if reaper.GetMediaItem_Track(it) ~= track then
    reaper.ShowMessageBox("All items must be on the same track.", "Shuffle Items", 0)
    reaper.PreventUIRefresh(-1)
    reaper.Undo_EndBlock("Shuffle Items - Error", -1)
    return
  end
end

-- Sort items by their position
table.sort(items, function(a, b)
  return reaper.GetMediaItemInfo_Value(a, "D_POSITION") < reaper.GetMediaItemInfo_Value(b, "D_POSITION")
end)

-- Snap items together without gaps
local pos = reaper.GetMediaItemInfo_Value(items[1], "D_POSITION")
for _, it in ipairs(items) do
  local len = reaper.GetMediaItemInfo_Value(it, "D_LENGTH")
  reaper.SetMediaItemInfo_Value(it, "D_POSITION", pos)
  pos = pos + len
end

reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock("Shuffle Items on One Track", -1)

