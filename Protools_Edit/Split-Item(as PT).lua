--[[
@description Smart Split at Time Selection or Cursor (PT-cmd E)
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-06-07)
  - Initial release
@provides
  [main] Protools_Edit/Split-Item(as PT).lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags editing, items, split, prottools-like
@about
  # Split Item (ProTools-like)
  Behaves like Pro Tools' standard split:
  - If a time selection exists, the item(s) are split at its boundaries.
  - Otherwise, the script splits at the edit cursor, using zero-crossing when possible.
  Automatically selects items under the edit cursor before splitting.
--]]


-- 1) Select items under edit cursor (Xenakios/SWS)
reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_SELITEMSUNDEDCURSELTX"), 0)

-- 2) Check if a Time Selection exists
local start_time, end_time = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)
local has_time_selection = (end_time > start_time)

-- 3) If Time Selection exists -> place cursor at its start (40630)
if has_time_selection then
    reaper.Main_OnCommand(40630, 0) -- Go to start of time selection
end

-- 4) Split depending on condition
if has_time_selection then
    reaper.Main_OnCommand(40061, 0) -- Split at time selection or razor edit
else
    reaper.Main_OnCommand(40792, 0) -- Split at cursor (zero crossing)
end

-- 5) Unselect all items
reaper.Main_OnCommand(40289, 0)

-- 6) Remove time selection
reaper.Main_OnCommand(40020, 0)

reaper.UpdateArrange()

