--[[
@description Trim Left & Right edges of selected item to adjacent items on same track (with left edge check)
@version 1.1
@author Mariow
@changelog
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

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

-- ==============================
-- PARTIE 1 : Trim left edge to previous item (with condition)
-- ==============================

local item = reaper.GetSelectedMediaItem(0, 0)
if item then
    local track = reaper.GetMediaItemTrack(item)
    local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    
    -- Chercher l'item précédent
    local item_count = reaper.CountTrackMediaItems(track)
    local prev_item = nil
    local prev_end = -math.huge

    for i = 0, item_count - 1 do
        local it = reaper.GetTrackMediaItem(track, i)
        local it_end = reaper.GetMediaItemInfo_Value(it, "D_POSITION") + reaper.GetMediaItemInfo_Value(it, "D_LENGTH")
        if it_end <= item_pos and it_end > prev_end then
            prev_item = it
            prev_end = it_end
        end
    end

    -- Condition : si le bord gauche correspond déjà au bord droit du précédent, ne rien faire
    if prev_item and math.abs(item_pos - prev_end) > 0.0001 then
        -- Déplacer la position gauche
        local item_end = item_pos + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        reaper.SetMediaItemInfo_Value(item, "D_POSITION", prev_end)
        -- Ajuster la longueur pour conserver le bord droit
        reaper.SetMediaItemInfo_Value(item, "D_LENGTH", item_end - prev_end)
    end
end

-- ==============================
-- PARTIE 2 : Trim right edge to next item on same track
-- ==============================

if item then
    local track = reaper.GetMediaItemTrack(item)
    local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    local item_end = item_pos + item_len

    local item_count = reaper.CountTrackMediaItems(track)
    local closest = nil
    local closest_start = math.huge

    for i = 0, item_count - 1 do
        local it = reaper.GetTrackMediaItem(track, i)
        if it ~= item then
            local it_pos = reaper.GetMediaItemInfo_Value(it, "D_POSITION")
            if it_pos >= item_end and it_pos < closest_start then
                closest = it
                closest_start = it_pos
            end
        end
    end

    if closest then
        local new_len = closest_start - item_pos
        reaper.SetMediaItemInfo_Value(item, "D_LENGTH", new_len)
    end
end

-- ==============================
-- FIN DU SCRIPT
-- ==============================

reaper.UpdateArrange()
reaper.Undo_EndBlock("Trim left & right edges (with left edge check)", -1)
reaper.PreventUIRefresh(-1)
