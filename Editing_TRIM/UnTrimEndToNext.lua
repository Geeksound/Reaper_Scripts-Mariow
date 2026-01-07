--[[
@description Trim Right Edge of Selected Item to Next Item on Same Track
@version 1.1
@author Mariow
@changelog
  v1.1
- Process all selected items one by one safely
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

-- @noindex

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

-- Compter les items sélectionnés
local count_sel = reaper.CountSelectedMediaItems(0)
if count_sel == 0 then
  reaper.MB("Aucun item sélectionné", "Erreur", 0)
  return
end

-- Stocker les items sélectionnés
local items = {}
for i = 0, count_sel - 1 do
  local item = reaper.GetSelectedMediaItem(0, i)
  if item then
    items[#items + 1] = item
  end
end

-- Désélectionner tous les items
reaper.SelectAllMediaItems(0, false)

-- Traiter les items un par un
for i = 1, #items do
  local item = items[i]
  
  if reaper.ValidatePtr(item, "MediaItem*") then
    -- Sélectionner uniquement l’item courant
    reaper.SelectAllMediaItems(0, false)
    reaper.SetMediaItemSelected(item, true)
    
    local track = reaper.GetMediaItemTrack(item)
    local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    local item_end = item_pos + item_len
    
    local item_count = reaper.CountTrackMediaItems(track)
    local next_item = nil
    local next_start = math.huge
    
    for j = 0, item_count - 1 do
      local it = reaper.GetTrackMediaItem(track, j)
      if it ~= item then
        local it_pos = reaper.GetMediaItemInfo_Value(it, "D_POSITION")
        if it_pos >= item_end and it_pos < next_start then
          next_item = it
          next_start = it_pos
        end
      end
    end
    
    -- Appliquer le trim uniquement si un item suivant existe
    if next_item then
      local new_len = next_start - item_pos
      if new_len > 0 then
        reaper.SetMediaItemInfo_Value(item, "D_LENGTH", new_len)
      end
    end
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
reaper.Undo_EndBlock("Trim Right Edge to Next Item (sequential)", -1)