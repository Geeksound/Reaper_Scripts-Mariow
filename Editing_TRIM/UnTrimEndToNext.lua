--[[
@description Trim Right Edge of Selected Item to Next Item on Same Track
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-11-06)
  - Initial release
  - Automatically trims the right edge of the selected item to Start of next item on the same track

@provides
  [main] Editing_TRIM/UnTrimEndToNext.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags items, editing, trimming, utility
@about
  # Trim Right Edge to Next Item
  This script automatically trims the **right edge** of the selected item
  so that it aligns precisely with the **start of the next item** on the same track.
  
  Useful for cleaning up overlapping items or ensuring tight sequential edits
  when working on dialogue, sound effects, or music clips.
--]]

reaper.Undo_BeginBlock()

local item = reaper.GetSelectedMediaItem(0, 0)
if item then
    local track = reaper.GetMediaItemTrack(item)
    local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    local item_end = item_pos + item_len

    local item_count = reaper.CountTrackMediaItems(track)
    local closest = nil
    local closest_start = math.huge

    for i = 0, item_count - 1 do
        local it = reaper.GetTrackMediaItem(track, i)
        if it ~= item then
            local it_pos = reaper.GetMediaItemInfo_Value(it, "D_POSITION")
            if it_pos >= item_end and it_pos < closest_start then
                closest = it
                closest_start = it_pos
            end
        end
    end

    if closest then
        local new_len = closest_start - item_pos
        reaper.SetMediaItemInfo_Value(item, "D_LENGTH", new_len)
    end
end

reaper.UpdateArrange()
reaper.Undo_EndBlock("Trim right edge to next item", -1)
