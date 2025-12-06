--[[
@description SnapItemToNext(ProTools-like)
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-11-26)
  - Initial release: moves selected item so its right edge aligns with next item on the same track
@provides
  [main] Protools_Edit/Snap-Item-ToNext.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags editing, items, snapping, alignment, (protools-like)
@about
  # Move item right edge to next item’s left edge (ProTools-like)
  Moves the selected item so that its right edge snaps exactly to the
  left edge of the next item on the same track, emulating Pro Tools' 
  edge-alignment workflow.
--]]


local r = reaper

local item = r.GetSelectedMediaItem(0,0)
if not item then return end

local track = r.GetMediaItem_Track(item)
local pos    = r.GetMediaItemInfo_Value(item, "D_POSITION")
local len    = r.GetMediaItemInfo_Value(item, "D_LENGTH")
local right  = pos + len

local itemCount = r.GetTrackNumMediaItems(track)
local nextStart = nil

for i = 0, itemCount-1 do
    local it = r.GetTrackMediaItem(track, i)
    if it ~= item then
        local p = r.GetMediaItemInfo_Value(it, "D_POSITION")
        if p > right and (not nextStart or p < nextStart) then
            nextStart = p
        end
    end
end

if nextStart then
    local newPos = nextStart - len
    r.Undo_BeginBlock()
    r.SetMediaItemInfo_Value(item, "D_POSITION", newPos)
    r.Undo_EndBlock("Move item to next item edge", -1)
end

