--[[
@description ProTools TAB - Contextual Reverse Tab Navigation (ALT+TAB)
@version 1.0
@author Mariow
@changelog
    v1.0 (2025-06-07)
    - Initial release
@provides
    [main] ProTools_TAB/(Protools)TAB(alt).lua
@tags protools, tab, reverse, navigation, transient, fade, editing, cursor
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@about
    # ProTools TAB - Reverse Navigation (ALT+TAB)
    
    This script performs the “reverse TAB” navigation found in Pro Tools,  
    using the global modes defined in the ProTools TAB system.
    
    Depending on the active mode, **ALT+TAB** will:
    - Jump to the previous item boundary  
    - Snap to previous fade-in / fade-out points when Fade mode is enabled  
    - Jump to the previous transient when TabToTransient is active  
    
    ## Behavior details
    
    ### When **TabToTransient** is enabled:
    ALT+TAB mirrors the backward Tab-to-Transient behavior in Pro Tools.
    
    ### When **Fade mode** is enabled:
    ALT+TAB navigates backward across:
    - Item end
    - Fade-out start (if present)
    - Fade-in end (if present)
    - Item start
    
    ### When no special mode is active:
    ALT+TAB simply cycles backward through:
    - Item end → Item start → Previous item end → ...
    
    ## Synchronization
    The navigation logic depends on the shared ExtState values:
    - `"Fade"`
    - `"TabToTransient"`
    
    These values are managed by the ImGui controller, toolbar buttons,  
    and keyboard shortcuts, ensuring perfect consistency in behavior.
    
    This script completes the ProTools-like backward editing workflow  
    by making ALT+TAB context-aware — just like in Pro Tools.
--]]

-- Vérifier si le mode TabToTransient est actif
local tab_to_transient = reaper.GetExtState("ProTools_TAB", "TabToTransient") == "1"
local fade_enabled = reaper.GetExtState("ProTools_TAB", "Fade") == "1"

-- Si TabToTransient actif, exécuter la série de commandes (prev transient)
if tab_to_transient then
    local commands = {
        40625, -- Set start point
        40626, -- Set end point
        40421, -- Select all items in track
        40434, -- Move edit to play cursor
        40376, -- Cursor to previous transient
        40289  -- Clear selection of items
    }
    for _, cmd_id in ipairs(commands) do
        reaper.Main_OnCommand(cmd_id, 0)
    end
else
    -- Sinon, exécution classique basée sur fade
    local cursor = reaper.GetCursorPosition()
    local selectedtracks = reaper.CountSelectedTracks(0)
    local positions = {}

    for i = 0, selectedtracks-1 do
        local track = reaper.GetSelectedTrack(0, i)
        local itemnum = reaper.CountTrackMediaItems(track)
        for a = 0, itemnum-1 do
            local item = reaper.GetTrackMediaItem(track, a)
            local pos     = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
            local len     = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
            local fadein  = reaper.GetMediaItemInfo_Value(item, "D_FADEINLEN")
            local fadeout = reaper.GetMediaItemInfo_Value(item, "D_FADEOUTLEN")

            table.insert(positions, pos)
            if fade_enabled then
                if fadein > 0 then table.insert(positions, pos + fadein) end
                if fadeout > 0 then table.insert(positions, pos + len - fadeout) end
            end
            table.insert(positions, pos + len)
        end
    end

    table.sort(positions)

    local prev_pos = nil
    local tol = 0.000001
    for i = #positions, 1, -1 do
        if positions[i] < cursor - tol then
            prev_pos = positions[i]
            break
        end
    end
    if not prev_pos then prev_pos = positions[#positions] end

    reaper.SetEditCurPos(prev_pos, true, false)
end

