--[[
@description SyncPoint-ToEditCursor
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-11-12)
  - Initial release
@provides
  [main] PROTOOLS/SyncPoint-ToEditCursor.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags items, editing, snap, offset, protools, alignment
@about
  # Move item so that Snap Offset aligns with Edit Cursor (Pro Tools K)
  Emulates Pro Tools 'K' shortcut behavior in REAPER.
  Moves selected item(s) so that their Snap Offset aligns exactly with the Edit Cursor position.
  Useful for field recording or precise sync editing workflows.
  CF Editing/SnapOffsetToEditCursor (is the same) 
--]]

local cursor_pos = reaper.GetCursorPosition()
local count_sel_items = reaper.CountSelectedMediaItems(0)
if count_sel_items == 0 then
  reaper.MB("Please select an Item.", "Info", 0)
  return
end

reaper.Undo_BeginBlock()

for i = 0, count_sel_items - 1 do
  local item = reaper.GetSelectedMediaItem(0, i)
  
  -- Ignorer les items verrouillés
  if reaper.GetMediaItemInfo_Value(item, "C_LOCK") ~= 1 then
    local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local snap_offset = reaper.GetMediaItemInfo_Value(item, "D_SNAPOFFSET")
    local new_item_pos = cursor_pos - snap_offset
    reaper.SetMediaItemInfo_Value(item, "D_POSITION", new_item_pos)
  end
end

reaper.UpdateArrange()
reaper.Undo_EndBlock("Move item so Snap Offset aligns with Edit Cursor (Pro Tools K)", -1)

