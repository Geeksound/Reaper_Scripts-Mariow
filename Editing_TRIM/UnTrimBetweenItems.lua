--[[
@description Trim Left & Right edges of selected item to adjacent items on same track (with left edge check)
@version 1.1.1
@author Mariow
@changelog
  V1.1.1 (2025-12-02)
  - Bug Fix
  v1.1 (2025-11-06)
  - Added condition: left edge will not move if already aligned with previous item's right edge
  v1.0 (2025-11-06)
  - Combined left and right trim operations into a single script
  - Automatically trims selected item to previous and next items on the same track
  - Unified undo block for clean undo history
@provides
  [main] Editing_TRIM/UnTrimBetweenItems.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags items, editing, trimming, utility
@about
  # Trim Left & Right to Adjacent Items
  This script automatically trims the selected item edges so that:
  - The **left edge** aligns with the **end of the previous item** (only if not already aligned)
  - The **right edge** aligns with the **start of the next item**
  
  Works on the selected media item within the same track.
  Ideal for cleaning overlaps or creating tightly spaced item sequences without gaps.
--]]

-- @noindex

local function find_prev_positions(cursor)
  local positions = {}

  local sel_tracks = reaper.CountSelectedTracks(0)
  for i = 0, sel_tracks - 1 do
    local track = reaper.GetSelectedTrack(0, i)
    local item_count = reaper.CountTrackMediaItems(track)

    for j = item_count - 1, 0, -1 do
      local item = reaper.GetTrackMediaItem(track, j)
      local item_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
      local item_end = item_start + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

      if item_end < cursor then
        table.insert(positions, item_end)
        break
      elseif item_start < cursor then
        table.insert(positions, item_start)
        break
      end
    end
  end

  -- tri des positions en ordre croissant
  table.sort(positions)
  return positions[1]
end

local function main()
  -- Étape 1 : Time selection to items
  reaper.Main_OnCommand(40290, 0)

  -- Étape 2 : Go to start of time selection
  reaper.Main_OnCommand(40630, 0)

  -- Étape 3 : Calcul du nouveau curseur
  local cursor = reaper.GetCursorPosition()
  local new_pos = find_prev_positions(cursor)
  if new_pos then
    reaper.SetEditCurPos(new_pos, true, true)
  end

  -- Étape 4 : Trim left edge of item to edit cursor
  reaper.Main_OnCommand(41305, 0)

  -- Étape 5 : Set item ends to start of next item
  reaper.Main_OnCommand(41639, 0)
end

reaper.Undo_BeginBlock()
main()
reaper.Undo_EndBlock("Custom Script Sequence Optimised", -1)
