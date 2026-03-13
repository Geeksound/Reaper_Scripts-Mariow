--[[
@description Auto-Split Overlapping Items (Keep Top Item)
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-11-11)
  - When moving or pasting Item on another, Preserves selected (top) items and removes only overlapped portions below
@provides
  [main] Editing_TRIM/TrimAndSplitByItemOnTop.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags split, items, overlap, editing, automation
@about
  # Auto Split Overlapping Items (Keep Top Item)
  This script automatically splits overlapping media items on the same track.
  It removes only the parts of the lower items that are covered by the selected (top) items,
  leaving the top items intact.
  Useful for cleaning up overlapping takes or consolidating edits.

  Developed with the help of GitHub Copilot.
--]]

reaper.Undo_BeginBlock()

local num_sel_items = reaper.CountSelectedMediaItems(0)
if num_sel_items == 0 then
  reaper.ShowMessageBox("No item selected.", "Error", 0)
  return
end

-- Utility function: get item boundaries
local function GetItemBounds(item)
  local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  local len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
  return pos, pos + len
end

-- Function: split an item at a given position (if within its boundaries)
local function SplitItem(item, split_pos)
  local pos, endpos = GetItemBounds(item)
  if split_pos <= pos or split_pos >= endpos then return nil end
  return reaper.SplitMediaItem(item, split_pos)
end

-- Store all selected items so they are never deleted
local protected_items = {}
for i = 0, num_sel_items - 1 do
  local item = reaper.GetSelectedMediaItem(0, i)
  protected_items[item] = true
end

-- Check if an item is protected
local function IsProtected(item)
  return protected_items[item] ~= nil
end

-- Main loop
for i = 0, num_sel_items - 1 do
  local sel_item = reaper.GetSelectedMediaItem(0, i)
  local sel_track = reaper.GetMediaItem_Track(sel_item)
  local sel_start, sel_end = GetItemBounds(sel_item)

  local num_items = reaper.CountTrackMediaItems(sel_track)

  -- Iterate through all items on the track (except protected ones)
  for j = num_items - 1, 0, -1 do
    local other_item = reaper.GetTrackMediaItem(sel_track, j)
    if other_item ~= sel_item and not IsProtected(other_item) then
      local o_start, o_end = GetItemBounds(other_item)

      -- Overlap?
      if (o_start < sel_end) and (o_end > sel_start) then

        -- Split on the left
        local right_part = SplitItem(other_item, sel_start)

        -- Split on the right
        if right_part then
          SplitItem(right_part, sel_end)
        else
          SplitItem(other_item, sel_end)
        end

        -- Delete the overlapped portion (but not protected items)
        local num_after = reaper.CountTrackMediaItems(sel_track)
        for k = num_after - 1, 0, -1 do
          local piece = reaper.GetTrackMediaItem(sel_track, k)
          if not IsProtected(piece) then
            local p_start, p_end = GetItemBounds(piece)
            if (p_start >= sel_start) and (p_end <= sel_end) then
              reaper.DeleteTrackMediaItem(sel_track, piece)
            end
          end
        end
      end
    end
  end
end

reaper.UpdateArrange()
reaper.Undo_EndBlock("Auto Split Overlapping Items (Keep Top Item)", -1)

