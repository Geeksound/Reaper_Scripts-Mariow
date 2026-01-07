--[[
@description Trim Left Edge of Selected Item to Previous Item on Same Track (with left edge check)
@version 1.2
@author Mariow
@changelog
  v1.2
- Process all selected items one by one safely
  V.1.1.1 (2025-12-02)
  - Bug Fix
  v1.1 (2025-11-07)
  - Added condition: left edge will not move if already aligned with previous item's right edge
  v1.0 (2025-11-06)
  - Initial release
@provides
  [main] Editing_TRIM/UnTrimStartToPrev.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags items, editing, trimming, cursor, utility
@about
  # Trim Left Edge to Previous Item
  Automatically trims the **left edge** of the selected item
  to the **end of the previous item** on the same track, 
  but only if it's not already aligned.
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

-- Désélectionner tout
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
    
    -- Chercher l’item précédent sur la même piste
    local item_count = reaper.CountTrackMediaItems(track)
    local prev_item = nil
    local prev_end = -math.huge
    
    for j = 0, item_count - 1 do
      local it = reaper.GetTrackMediaItem(track, j)
      if it ~= item then
        local it_pos = reaper.GetMediaItemInfo_Value(it, "D_POSITION")
        local it_len = reaper.GetMediaItemInfo_Value(it, "D_LENGTH")
        local it_end = it_pos + it_len
        
        if it_end <= item_pos and it_end > prev_end then
          prev_item = it
          prev_end = it_end
        end
      end
    end
    
    -- Trim uniquement si nécessaire
    if prev_item and math.abs(item_pos - prev_end) > 0.0001 then
      reaper.SetEditCurPos(prev_end, false, false)
      -- 41305 = Item: Trim left edge of item to edit cursor
      reaper.Main_OnCommand(41305, 0)
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
reaper.Undo_EndBlock("Trim Left Edge to Previous Item (sequential)", -1)