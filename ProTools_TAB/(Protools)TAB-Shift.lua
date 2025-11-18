--[[
@description ProTools TAB - Shift+TAB (Extend Selection / Time Selection)
@version 1.0
@author Mariow
@changelog
    v1.0 (2025-11-17)
    - Initial release
@provides
    [main] ProTools_TAB/(ProTools)TAB-Shift.lua
@tags protools, tab, transient, fade, selection, timesel, editing
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@about
    # ProTools TAB - Shift+TAB (Extend Selection / Time Selection)
    
    Implements the **Shift+TAB behavior** from ProTools within REAPER's ProTools TAB workflow.
    
    Depending on the active mode, Shift+TAB will:
    
    - **TabToTransient Mode:** extend the Time Selection from the current cursor position 
        to the next transient, effectively allowing transient-to-transient selection.
    - **Fade Mode:** extend selection or Time Selection to fade points (fade-in, fade-out) 
        and/or item boundaries.
    - **Default Mode:** extend selection to the end of the next item.
    
    ## Features:
    - Fully respects the **contextual rules** of ProTools TAB.
    - Updates the Time Selection or item selection in a manner consistent with ProTools.
    - Works seamlessly with ImGui interface, toolbar buttons, and shared ExtState.
    - Allows entirely keyboard-driven workflow without losing synchronization.
    
    This script is ideal for **editing workflows that require precise selection extensions**
    in a ProTools-like manner, either by item edges, fade points, or transients.
--]]

-- Lire l'état du fade et TabToTransient depuis ProTools TAB
local fade_enabled = reaper.GetExtState("ProTools_TAB", "Fade") == "1"
local tab_transient = reaper.GetExtState("ProTools_TAB", "TabToTransient") == "1"

------------------------------------------------------------
-- ===============     TAB TO TRANSIENT ON      ===========
------------------------------------------------------------
if tab_transient then
    -- Exécuter la séquence de commandes pour aller au prochain transient
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_SELITEMSUNDEDCURSELTX"), 0)
    reaper.Main_OnCommand(40802, 0)
    reaper.Main_OnCommand(40631, 0)
    reaper.Main_OnCommand(40289, 0)

------------------------------------------------------------
-- ===============           FADE ON          =============
------------------------------------------------------------
elseif fade_enabled then

    -- Récupérer boucle et curseur
    local startOut, endOut = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
    local cursor = reaper.GetCursorPosition()

    if startOut > 0 then
        if cursor < startOut then
            reaper.GetSet_LoopTimeRange(true, false, cursor, cursor, false)
        else
            reaper.SetEditCurPos(endOut, true, false)
        end
    elseif startOut == 0 and endOut ~= 0 then
        reaper.SetEditCurPos(endOut, true, false)
    else
        reaper.GetSet_LoopTimeRange(true, false, cursor, cursor, false)
    end

    cursor = reaper.GetCursorPosition()

    -- Collecte positions items avec fades
    local selectedtracks = reaper.CountSelectedTracks(0)
    local positions = {}

    for i = 0, selectedtracks-1 do
        local track = reaper.GetSelectedTrack(0, i)
        local itemnum = reaper.CountTrackMediaItems(track)
        for a = 0, itemnum-1 do
            local item = reaper.GetTrackMediaItem(track, a)
            local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
            local len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
            local fadein = reaper.GetMediaItemInfo_Value(item, "D_FADEINLEN")
            local fadeout = reaper.GetMediaItemInfo_Value(item, "D_FADEOUTLEN")

            table.insert(positions, pos)
            if fadein > 0 then table.insert(positions, pos + fadein) end
            if fadeout > 0 then table.insert(positions, pos + len - fadeout) end
            table.insert(positions, pos + len)
        end
    end

    table.sort(positions)

    -- Trouver la position clé suivante
    local next_pos = nil
    local tol = 0.000001
    for i = 1, #positions do
        if positions[i] > cursor + tol then
            next_pos = positions[i]
            break
        end
    end
    if not next_pos then next_pos = positions[1] end

    -- Déplacer curseur et étendre TS
    reaper.SetEditCurPos(next_pos, true, true)
    startOut, endOut = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
    reaper.GetSet_LoopTimeRange(true, false, startOut, next_pos, false)
    reaper.Main_OnCommand(40718, 0)

    -- Désélection des items
    for i = 0, selectedtracks-1 do
        local track = reaper.GetSelectedTrack(0, i)
        local itemnum = reaper.CountTrackMediaItems(track)
        for a = 0, itemnum-1 do
            local item = reaper.GetTrackMediaItem(track, a)
            reaper.SetMediaItemSelected(item, false)
        end
    end

------------------------------------------------------------
-- ===============          FADE OFF         =============
------------------------------------------------------------
else
    -- Même logique que fade OFF classique (sans TabToTransient)
    local startOut, endOut = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
    local cursor = reaper.GetCursorPosition()
    local selectedtracks = reaper.CountSelectedTracks(0)
    local array = {}
    local b = 0

    if startOut > 0 then
        if cursor < startOut then
            reaper.GetSet_LoopTimeRange(true, false, cursor, cursor, false)
        else
            reaper.SetEditCurPos(endOut, true, false)
        end
    elseif startOut == 0 and endOut ~= 0 then
        reaper.SetEditCurPos(endOut, true, false)
    else
        reaper.GetSet_LoopTimeRange(true, false, cursor, cursor, false)
    end

    -- Collecte positions items
    for i = 0, selectedtracks-1 do
        local track = reaper.GetSelectedTrack(0, i)
        local itemnum = reaper.CountTrackMediaItems(track)
        for a = 0, itemnum-1 do
            local item = reaper.GetTrackMediaItem(track, a)
            local itemstart = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
            local itemend = itemstart + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
            if itemstart > cursor then
                array[b] = itemstart
                b = b + 1
                break
            elseif itemend > cursor then
                array[b] = itemend
                b = b + 1
                break
            end
        end
    end

    table.sort(array)
    if array[0] ~= nil then
        reaper.SetEditCurPos(array[0], true, true)
    end

    cursor = reaper.GetCursorPosition()
    startOut, endOut = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
    reaper.GetSet_LoopTimeRange(true, false, startOut, cursor, false)
    reaper.Main_OnCommand(40718, 0)
end

