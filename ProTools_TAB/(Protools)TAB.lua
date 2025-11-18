--[[
@description ProTools TAB - Contextual Tab Navigation (Items / Fades / Transients)
@version 1.0
@author Mariow
@changelog
    v1.0 (2025-06-07)
    - Initial release
@provides
    [main] ProTools_TAB/(Protools)TAB.lua
@tags protools, tab, navigation, transient, fade, editing, cursor
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@about
    # ProTools TAB - Contextual Tab Navigation
    
    This script reproduces the behavior of the **TAB navigation in Pro Tools**,  
    following the global logic defined by the other ProTools TAB scripts.
    
    Depending on the active mode, TAB will:
    - Move from the start to the end of items
    - Snap to fade-in / fade-out edges when Fade mode is enabled
    - Jump from transient to transient when TabToTransient is enabled
    
    ## Behavior details
    
    ### When **TabToTransient** is enabled:    TAB mirrors the Pro Tools “Tab to Transient” workflow.
    
    ### When **Fade mode** is enabled:
    TAB cycles through:
    - Item start
    - Fade-in end (if present)
    - Fade-out start (if present)
    - Item end
    
    This allows precise navigation across item edges and fades.
    
    ### When no special mode is active:
    TAB simply jumps between:
    - Item start → Item end → Next item start → ...
    
    ## Synchronization
    The navigation mode depends entirely on the shared ExtState:
    - `"Fade"`
    - `"TabToTransient"`
    
    These values are controlled by the ImGui interface, toolbar buttons,
    and keyboard shortcuts of the ProTools TAB system, ensuring consistent
    behavior across all workflows.
    
    This script completes the ProTools-like editing experience by making
    the TAB key context-aware, just like in Pro Tools.
--]]


local tab_to_transient = reaper.GetExtState("ProTools_TAB", "TabToTransient") == "1"
local fade_enabled = reaper.GetExtState("ProTools_TAB", "Fade") == "1"

-- Si TabToTransient actif, exécuter la série de commandes (next transient)
if tab_to_transient then
    local commands = {
        40625, -- Set start point
        40626, -- Set end point
        40421, -- Select all items in track
        40434, -- Move edit to play cursor
        40375, -- Cursor to next transient
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

    local next_pos = nil
    local tol = 0.000001
    for i = 1, #positions do
        if positions[i] > cursor + tol then
            next_pos = positions[i]
            break
        end
    end
    if not next_pos then next_pos = positions[1] end

    reaper.SetEditCurPos(next_pos, true, false)
end

