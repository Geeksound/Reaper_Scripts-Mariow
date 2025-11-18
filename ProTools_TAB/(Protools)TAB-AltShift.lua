--[[
@description ProTools TAB - Alt+Shift+TAB (Extend Selection / Time Selection Left)
@version 1.0
@author Mariow
@changelog
    v1.0 (2025-11-17)
    - Initial release
@provides
    [main] ProTools_TAB/(ProTools)TAB-AltShift.lua
@tags protools, tab, transient, fade, selection, timesel, editing, reverse
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@about
    # ProTools TAB - Alt+Shift+TAB (Extend Selection / Time Selection Left)
    
    Implements the **Alt+Shift+TAB behavior** from ProTools within REAPER's ProTools TAB workflow.
    
    Depending on the active mode, Alt+Shift+TAB will:
    
    - **TabToTransient Mode:** extend the Time Selection from the current cursor position 
        to the previous transient, allowing transient-to-transient selection in reverse.
    - **Fade Mode:** extend selection or Time Selection to fade points (fade-in, fade-out) 
        and/or item boundaries towards the left.
    - **Default Mode:** extend selection to the start of the previous item.
    
    ## Features:
    - Fully respects the **contextual rules** of ProTools TAB in reverse.
    - Updates the Time Selection or item selection in a ProTools-like manner to the left.
    - Works seamlessly with ImGui interface, toolbar buttons, and shared ExtState.
    - Enables precise, keyboard-driven selection extension in reverse.
--]]

-- Lire l'état du fade et TabToTransient depuis ProTools TAB
local fade_enabled = reaper.GetExtState("ProTools_TAB", "Fade") == "1"
local tab_transient = reaper.GetExtState("ProTools_TAB", "TabToTransient") == "1"

------------------------------------------------------------
-- ===============     TAB TO TRANSIENT ON      ===========
------------------------------------------------------------
if tab_transient then
    -- Exécuter la séquence de commandes pour aller au transient précédent
    local xenakios_sel = reaper.NamedCommandLookup("_XENAKIOS_SELITEMSUNDEDCURSELTX")
    local sws_unsetrepeat = reaper.NamedCommandLookup("_SWS_UNSETREPEAT")
    local sws_unselontracks = reaper.NamedCommandLookup("_SWS_UNSELONTRACKS")

    reaper.Main_OnCommand(xenakios_sel, 0)
    reaper.Main_OnCommand(40630, 0)
    reaper.Main_OnCommand(40102, 0)
    reaper.Main_OnCommand(40376, 0)
    reaper.Main_OnCommand(sws_unsetrepeat, 0)
    reaper.Main_OnCommand(40625, 0)
    reaper.Main_OnCommand(sws_unselontracks, 0)

------------------------------------------------------------
-- ===============           FADE ON          =============
------------------------------------------------------------
elseif fade_enabled then
    local startOut, endOut = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
    local cursor = reaper.GetCursorPosition()

    if startOut > 0 then
        if cursor > startOut then
            reaper.GetSet_LoopTimeRange(true, false, cursor, cursor, false)
        else
            reaper.SetEditCurPos(startOut, true, false)
        end
    elseif startOut == 0 and endOut ~= 0 then
        reaper.SetEditCurPos(startOut, true, false)
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

    -- Trouver la position clé précédente
    local prev_pos = nil
    local tol = 0.000001
    for i = #positions, 1, -1 do
        if positions[i] < cursor - tol then
            prev_pos = positions[i]
            break
        end
    end
    if not prev_pos then prev_pos = positions[#positions] end

    reaper.SetEditCurPos(prev_pos, true, true)

    -- Étendre TS vers la gauche
    startOut, endOut = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
    reaper.GetSet_LoopTimeRange(true, false, prev_pos, endOut, false)
    reaper.Main_OnCommand(40718, 0)

    -- Désélection items
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
    -- Même logique que fade OFF classique
    local startOut, endOut = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
    local cursor = reaper.GetCursorPosition()
    local selectedtracks = reaper.CountSelectedTracks(0)
    local positions = {}

    if startOut > 0 then
        if cursor > startOut then
            reaper.GetSet_LoopTimeRange(true, false, cursor, cursor, false)
        else
            reaper.SetEditCurPos(startOut, true, false)
        end
    elseif startOut == 0 and endOut ~= 0 then
        reaper.SetEditCurPos(startOut, true, false)
    else
        reaper.GetSet_LoopTimeRange(true, false, cursor, cursor, false)
    end

    -- Collecte positions items sans fade
    for i = 0, selectedtracks-1 do
        local track = reaper.GetSelectedTrack(0, i)
        local itemnum = reaper.CountTrackMediaItems(track)
        for a = 0, itemnum-1 do
            local item = reaper.GetTrackMediaItem(track, a)
            local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
            local len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
            table.insert(positions, pos)
            table.insert(positions, pos + len)
        end
    end

    table.sort(positions)

    -- Trouver position précédente
    local prev_pos = nil
    local tol = 0.000001
    for i = #positions, 1, -1 do
        if positions[i] < cursor - tol then
            prev_pos = positions[i]
            break
        end
    end
    if not prev_pos then prev_pos = positions[#positions] end

    reaper.SetEditCurPos(prev_pos, true, true)
    startOut, endOut = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
    reaper.GetSet_LoopTimeRange(true, false, prev_pos, endOut, false)
    reaper.Main_OnCommand(40718, 0)
end

