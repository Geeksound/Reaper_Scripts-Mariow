--[[
@description Trim Left & Right edges of selected item to adjacent items on same track (with left edge check)
@version 1.1.2
@author Mariow
@changelog
  V1.1.2 (2025-12-03)
  - Bug Fix
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

-- SAFE PATCH : empêche le trim gauche destructif

-- Safe Trim Left & Right based on adjacent items

local function get_adjacent_items(track, item)
  local item_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  local item_end   = item_start + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

  local prev_item_end = nil
  local next_item_start = nil

  local count = reaper.CountTrackMediaItems(track)
  for i = 0, count - 1 do
    local other = reaper.GetTrackMediaItem(track, i)
    if other ~= item then

      local s = reaper.GetMediaItemInfo_Value(other, "D_POSITION")
      local e = s + reaper.GetMediaItemInfo_Value(other, "D_LENGTH")

      -- item précédent (bord droit)
      if e <= item_start and (not prev_item_end or e > prev_item_end) then
        prev_item_end = e
      end

      -- item suivant (bord gauche)
      if s >= item_end and (not next_item_start or s < next_item_start) then
        next_item_start = s
      end

    end
  end

  return prev_item_end, next_item_start
end


local function main()
  local item = reaper.GetSelectedMediaItem(0, 0)
  if not item then return end

  local track = reaper.GetMediaItem_Track(item)

  -- Positions de l’item sélectionné
  local item_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  local item_end   = item_start + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

  -- Chercher les voisins
  local prev_end, next_start = get_adjacent_items(track, item)

  ------------------------------------------------
  -- 🟩 1. POSITIONNER CURSEUR AU DÉBUT DE L’ITEM
  ------------------------------------------------
  reaper.SetEditCurPos(item_start, false, false)

  ------------------------------------------------
  -- 🟩 2. SI UN ITEM PRÉCÉDENT EXISTE → CURSEUR = SON BORD DROIT
  ------------------------------------------------
  if prev_end then
    reaper.SetEditCurPos(prev_end, false, false)

    ------------------------------------------------
    -- 🟩 3. TRIM LEFT (SÉCURISÉ)
    ------------------------------------------------
    reaper.Main_OnCommand(41305, 0) -- Trim left edge to cursor
  end

  ------------------------------------------------
  -- 🟦 4. TRIM RIGHT vers l'item suivant (commande native)
  ------------------------------------------------
  if next_start then
    reaper.Main_OnCommand(41639, 0)
  end

  reaper.UpdateArrange()
end


reaper.Undo_BeginBlock()
main()
reaper.Undo_EndBlock("Trim edges to adjacent items (stable)", -1)

