--[[
@description Snap Item to Previous (ProTools-like)
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-11-26)
  - Initial release: moves selected item so its left edge aligns with the previous item on the same track
@provides
  [main] Protools_Edit/Snap-Item-ToPrevious.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags editing, items, snapping, alignment, (protools-like)
@about
  # Move item left edge to previous item’s right edge (ProTools-like)
  Moves the selected item so that its left edge snaps exactly to the
  right edge of the previous item on the same track, emulating 
  Pro Tools' reverse edge-alignment workflow.
--]]

local r = reaper

local item = r.GetSelectedMediaItem(0,0)
if not item then return end

local track = r.GetMediaItem_Track(item)
local pos    = r.GetMediaItemInfo_Value(item, "D_POSITION")
local len    = r.GetMediaItemInfo_Value(item, "D_LENGTH")

local itemCount = r.GetTrackNumMediaItems(track)
local prevEnd = nil

for i = 0, itemCount-1 do
    local it = r.GetTrackMediaItem(track, i)
    if it ~= item then
        local p = r.GetMediaItemInfo_Value(it, "D_POSITION")
        local l = r.GetMediaItemInfo_Value(it, "D_LENGTH")
        local right = p + l

        if right < pos and (not prevEnd or right > prevEnd) then
            prevEnd = right
        end
    end
end

if prevEnd then
    r.Undo_BeginBlock()
    r.SetMediaItemInfo_Value(item, "D_POSITION", prevEnd)
    r.Undo_EndBlock("Move item to previous item edge", -1)
end

