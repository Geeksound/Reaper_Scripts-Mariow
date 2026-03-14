--[[
@description Grow (Untrim) Left Edge of Selected Items by Nudge Value (reads timecode from PRE-POST-ROLL ImGui panel)
@version 1.0
@author Mariow
@changelog
    v1.0 (2025-12-09)
    - Initial release (extends left edge of selected items based on TimecodeUI value)
@provides
    [main] ProTools_Essentials/GrowLeftEdge-TCui.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags editing, nudge, item, trim, transport, (protools-like)
@about
    # Grow (Untrim) Left Edge of Selected Items (ProTools-like)
    
    This script moves the **left edge** of each selected media item backward
    by a duration defined in the companion **Unified PRE-POST-ROLL + Timecode UI (ImGui)** panel.
    
    ## 🟦 Timecode Input (Shared Setting)
    The nudge amount is read from the shared ExtState:
    
    - Namespace: **"TimecodeUI"**  
    - Key: **"tc"**  
    - Format: `HH:MM:SS:FF` (frames based; currently 25 fps)
    
    This value is written dynamically by:
    
    **PRE-POST-ROLL + Timecode UI (No Title, Draggable)**
    
    Using this shared timecode ensures consistent behavior across all
    ProTools-like editing and navigation scripts.
    
    ## 🟩 Usage
    - Only affects **selected items**.  
    - Moves the left edge of each item backward by the Timecode value (untrimming the item).  
    - The edit cursor is temporarily moved to the new left edge to perform the trim operation.  
    - Undo is fully supported via REAPER's undo system.
    
    ## 🔗 Part of the ProTools_Essentials Suite
    Works in conjunction with:
    
    - Grow Right Edge (if available)  
    - Nudge Forward / Backward  
    - Nudge Forward ×10 / Backward ×10  
    - PRE-POST-ROLL + Timecode UI (ImGui)  
    - Set_Rolls_And_Nudge_Settings  
    - Other transport and editing tools
    
    Together, these scripts provide a unified, Pro Tools–style editing workflow in REAPER.
--]]


local function read_tc()
    local tc = reaper.GetExtState("TimecodeUI","tc")
    if not tc or tc == "" then return 0 end
    local h, m, s, f = tc:match("(%d+):(%d+):(%d+):(%d+)")
    if not h then return 0 end
    local fps = 25
    return h*3600 + m*60 + s + f/fps
end

local function grow_left()
    local delta = read_tc()
    if delta == 0 then return end

    local item_count = reaper.CountSelectedMediaItems(0)
    if item_count == 0 then return end

    reaper.Undo_BeginBlock()
    
    for i = 0, item_count-1 do
        local item = reaper.GetSelectedMediaItem(0,i)
        local pos  = reaper.GetMediaItemInfo_Value(item,"D_POSITION")
        
        -- Déplacer le curseur vers la gauche du bord gauche de l'item
        local new_pos = pos - delta
        if new_pos < 0 then new_pos = 0 end
        reaper.SetEditCurPos(new_pos,true,false)
        
        -- Trim left edge to cursor = déplace uniquement le bord gauche
        reaper.Main_OnCommand(41305,0)
    end

    reaper.Undo_EndBlock("Grow Left Edge by Nudge", -1)
end

grow_left()

