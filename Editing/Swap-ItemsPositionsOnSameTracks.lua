-- @description  Swap the position of 2 selected items
-- @author Mariow
-- @version 1.0
-- @changelog Initial release
-- @provides
--   [main] Editing/Swap-ItemsPositionsOnSameTracks.lua
-- @link https://github.com/Geeksound/Reaper_Scripts-Mariow
-- @tags items, editing
-- @about
--   # Swap-ItemsPositionsOnSameTracks
--   Contextual Swap to Between to Items for listening A/B for Reaper 7.0.
-- This script was developed with the help of GitHub Copilot.

-- Check that exactly 2 items are selected
local item_count = reaper.CountSelectedMediaItems(0)
if item_count ~= 2 then
reaper.MB("Please select exactly 2 items.", "Error", 0)
return
end

-- Get the two items
local item1 = reaper.GetSelectedMediaItem(0, 0)
local item2 = reaper.GetSelectedMediaItem(0, 1)

-- Get their positions
local pos1 = reaper.GetMediaItemInfo_Value(item1, "D_POSITION")
local pos2 = reaper.GetMediaItemInfo_Value(item2, "D_POSITION")

-- Begin undo block
reaper.Undo_BeginBlock()

-- Swap positions
reaper.SetMediaItemInfo_Value(item1, "D_POSITION", pos2)
reaper.SetMediaItemInfo_Value(item2, "D_POSITION", pos1)

-- End undo block
reaper.Undo_EndBlock("Swap position of 2 selected items", -1)

-- Refresh arrangement view
reaper.UpdateArrange()
