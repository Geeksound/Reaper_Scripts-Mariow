--[[
@description Trim Left Edge of Selected Item to Previous Item on Same Track (with left edge check)
@version 1.1.1
@author Mariow
@changelog
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

local item = reaper.GetSelectedMediaItem(0, 0)
if item then
    local track = reaper.GetMediaItemTrack(item)
    local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")

    -- Trouver le précédent item sur la même piste
    local item_count = reaper.CountTrackMediaItems(track)
    local prev_item = nil
    local prev_end = -math.huge

    for i = 0, item_count - 1 do
        local it = reaper.GetTrackMediaItem(track, i)
        local it_pos = reaper.GetMediaItemInfo_Value(it, "D_POSITION")
        local it_len = reaper.GetMediaItemInfo_Value(it, "D_LENGTH")
        local it_end = it_pos + it_len

        if it_end <= item_pos and it_end > prev_end then
            prev_item = it
            prev_end = it_end
        end
    end

    -- Vérifier qu’il y a un item précédent ET pas déjà aligné
    if prev_item and math.abs(item_pos - prev_end) > 0.0001 then
        
        -- 1. placer le curseur
        reaper.SetEditCurPos(prev_end, false, false)
        
        -- 2. utiliser la commande native : Trim left edge to edit cursor
        -- 41305 = "Item: Trim left edge of item to edit cursor"
        reaper.Main_OnCommand(41305, 0)
    end
end

reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock("Trim Left Edge to Previous Item (safe)", -1)
