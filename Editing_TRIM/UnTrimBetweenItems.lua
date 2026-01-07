--[[
@description Trim Left & Right edges of selected item to adjacent items on same track (with left edge check)
@version 1.2
@author Mariow
@changelog
  v1.2
- Process all selected items one by one safely
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

------------------------------------------------
-- 🔧 Fonctions utilitaires
------------------------------------------------

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
      
      -- Item précédent (bord droit)
      if e <= item_start and (not prev_item_end or e > prev_item_end) then
        prev_item_end = e
      end
      
      -- Item suivant (bord gauche)
      if s >= item_end and (not next_item_start or s < next_item_start) then
        next_item_start = s
      end
    end
  end
  
  return prev_item_end, next_item_start
end


------------------------------------------------
-- 🧠 Traitement d’un item unique
------------------------------------------------

local function process_item(item)
  if not reaper.ValidatePtr(item, "MediaItem*") then return end
  
  local track = reaper.GetMediaItemTrack(item)
  if not track then return end
  
  local item_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  local item_len   = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
  local item_end   = item_start + item_len
  
  local prev_end, next_start = get_adjacent_items(track, item)
  
  ------------------------------------------------
  -- 🟩 TRIM LEFT (sécurisé)
  ------------------------------------------------
  if prev_end and math.abs(item_start - prev_end) > 0.0001 then
    reaper.SetEditCurPos(prev_end, false, false)
    reaper.Main_OnCommand(41305, 0) -- Trim left edge to cursor
  end
  
  ------------------------------------------------
  -- 🟦 TRIM RIGHT (vers item suivant)
  ------------------------------------------------
  if next_start then
    reaper.Main_OnCommand(41639, 0) -- Trim right edge to next item
  end
end


------------------------------------------------
-- 🚀 MAIN — traitement séquentiel
------------------------------------------------

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

local count_sel = reaper.CountSelectedMediaItems(0)
if count_sel == 0 then
  reaper.MB("Aucun item sélectionné", "Erreur", 0)
  reaper.PreventUIRefresh(-1)
  reaper.Undo_EndBlock("Trim edges to adjacent items (sequential)", -1)
  return
end

-- Sauvegarder la sélection
local items = {}
for i = 0, count_sel - 1 do
  local item = reaper.GetSelectedMediaItem(0, i)
  if item then
    items[#items + 1] = item
  end
end

-- Désélectionner tout
reaper.SelectAllMediaItems(0, false)

-- Traiter chaque item individuellement
for i = 1, #items do
  local item = items[i]
  if reaper.ValidatePtr(item, "MediaItem*") then
    reaper.SelectAllMediaItems(0, false)
    reaper.SetMediaItemSelected(item, true)
    process_item(item)
  end
end

-- Restaurer la sélection initiale
reaper.SelectAllMediaItems(0, false)
for i = 1, #items do
  if reaper.ValidatePtr(items[i], "MediaItem*") then
    reaper.SetMediaItemSelected(items[i], true)
  end
end

reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock("Trim edges to adjacent items (sequential)", -1)
