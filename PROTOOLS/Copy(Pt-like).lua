--[[
@description Copy PT-like (ignore time selection) + move cursor to source start
@version 1.0
@author Mariow
@changelog
  v1.0 (2026-02-24)
  - Initial release
  - Executes "Copy items/tracks/envelope points (ignoring time selection)"
  - Moves edit cursor to start of first selected item
  - Falls back to start of Time Selection if no items are selected
@provides
  [main] PROTOOLS/Copy(Pt-like).lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags copy, protools, cursor, editing, workflow
@about
  # Copy PT-like + Smart Cursor Reposition

  This script reproduces a Pro Tools-style copy behavior inside REAPER.

  Workflow:
  • Executes "Copy items/tracks/envelope points (depending on focus) ignoring time selection"
  • If items are selected → moves edit cursor to start of first selected item
  • If no items are selected → moves edit cursor to start of Time Selection

  Designed for fast dialog editing and PT-style source-based workflows.
--]]

-- 1️⃣ Count selected items
local num_items = reaper.CountSelectedMediaItems(0)

-- 2️⃣ Execute copy (ignoring Time Selection)
reaper.Main_OnCommand(40057, 0)

-- 3️⃣ Move cursor
if num_items > 0 then
    -- Move cursor to start of first selected item
    local first_item = reaper.GetSelectedMediaItem(0, 0)
    local item_pos = reaper.GetMediaItemInfo_Value(first_item, "D_POSITION")
    reaper.SetEditCurPos(item_pos, true, false)
else
    -- No items selected → move to start of Time Selection
    reaper.Main_OnCommand(40630, 0)
end

reaper.UpdateArrange()

-- Based on Edit: Copy items/tracks/envelope points (depending on focus) ignoring time selection
