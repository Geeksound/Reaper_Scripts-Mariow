--[[
@description Trim Left Edge of Selected Item to Previous Item on Same Track
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-11-06)
  - Initial release
  - Trim the Left Edge of Selected Item To End of Previous Item if possibley
@provides
  [main] Editing_TRIM/UnTrimStartToPrev.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags items, editing, trimming, cursor, utility
@about
  # Trim Left Edge to Previous Item
  This script automatically trims the **left edge** of the selected item
  so that it aligns precisely with the **end of the previous item** on the same track.
  
  It first moves the edit cursor to the start of the item,
  then locates the nearest item before it on the same track,
  and finally trims the left edge of the selected item to match that point.
  
  Ideal for quickly aligning clips or cleaning overlaps when editing dialogue,
  SFX, or tightly cut audio segments.
--]]

--=== Fonction locale (issue du script précédent) ===--
local function MoveCursorToPreviousItemEdge()
    local cursor = reaper.GetCursorPosition()
    local selectedtracks = reaper.CountSelectedTracks(0)
    local array = {}
    local arraytemp = {}
    local b = 0

    for i = 0, selectedtracks - 1 do
        local track = reaper.GetSelectedTrack(0, i)
        local itemnum = reaper.CountTrackMediaItems(track)
        for a = 0, itemnum - 1 do
            local item = reaper.GetTrackMediaItem(track, itemnum - a - 1)
            local itemstart = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
            local itemend = itemstart + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

            if itemend < cursor then
                array[b] = itemend
                b = b + 1
                break
            elseif itemstart < cursor then
                array[b] = itemstart
                b = b + 1
                break
            end
        end
    end

    -- Tri en ordre croissant
    for i = 0, b - 1 do
        for m = 0, b - 2 do
            if array[m] > array[m + 1] then
                arraytemp[0] = array[m]
                array[m] = array[m + 1]
                array[m + 1] = arraytemp[0]
            end
        end
    end

    if array[0] ~= nil then
        reaper.SetEditCurPos(array[0], true, true)
    end
end

--=== SCRIPT PRINCIPAL ===--
reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

-- Étape 1 : Move cursor to start of items (Command ID 41173)
reaper.Main_OnCommand(41173, 0)

-- Étape 2 : Appeler la fonction personnalisée
MoveCursorToPreviousItemEdge()

-- Étape 3 : Trim left edge of item to edit cursor (Command ID 41305)
reaper.Main_OnCommand(41305, 0)

reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock("Move to start, move to previous edge, trim left edge", -1)

