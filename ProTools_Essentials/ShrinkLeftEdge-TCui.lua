--[[
@description Trim Left Edge of Selected Items by Nudge Value (TimecodeUI)
@version 1.0
@author Mariow
@changelog
    v1.0 (2025-12-09)
    - Initial release (trims left edge of selected items using TimecodeUI nudge value)
@provides
    [main] ProTools_Essentials/ShrinkLeftEdge-TCui.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags editing, trim, items, nudge, transport, (protools-like)
@about
    # Trim Left Edge by Nudge Value (ProTools-like)
    
    This script trims the **left edge** of selected items by a duration defined in
    the companion **Unified PRE-POST-ROLL + Timecode UI (ImGui)** panel.
    
    ## 🟦 Timecode Input (Shared Setting)
    - Namespace: **"TimecodeUI"**
    - Key: **"tc"**
    - Format: `HH:MM:SS:FF` (frames based; currently 25 fps)
    
    The script reads the nudge value from this shared ExtState, ensuring
    synchronization with all other nudge/transport scripts in the suite.
    
    ## 🟩 Usage
    - Only affects **selected items**.  
    - Trims the **left edge** of each selected item by the nudge amount.  
    - The edit cursor is temporarily moved to the new left edge to perform the trim.  
    - Undo is fully supported via REAPER's undo system.
    
    ## 🔗 Part of the ProTools_Essentials Suite
    Works in conjunction with:
    
    - Grow Left / Grow Right Edge  
    - Nudge Forward / Nudge Backward  
    - PRE-POST-ROLL + Timecode UI (ImGui)  
    - Set_Rolls_And_Nudge_Settings  
    - Other transport/navigation scripts
    
    Together, these scripts provide a consistent, Pro Tools–like editing workflow in REAPER.
--]]


local function read_tc()
    local tc = reaper.GetExtState("TimecodeUI","tc")
    if not tc or tc == "" then return 0 end
    local h, m, s, f = tc:match("(%d+):(%d+):(%d+):(%d+)")
    if not h then return 0 end
    local fps = 25
    return h*3600 + m*60 + s + f/fps
end

local function trim_left()
    local delta = read_tc()
    if delta == 0 then return end

    local item_count = reaper.CountSelectedMediaItems(0)
    if item_count == 0 then return end

    reaper.Undo_BeginBlock()
    
    for i = 0, item_count-1 do
        local item = reaper.GetSelectedMediaItem(0,i)
        local pos  = reaper.GetMediaItemInfo_Value(item,"D_POSITION")
        local len  = reaper.GetMediaItemInfo_Value(item,"D_LENGTH")
        
        local new_pos = pos + delta
        if new_pos > pos + len then new_pos = pos + len end
        
        reaper.SetEditCurPos(new_pos,true,false)
        reaper.Main_OnCommand(41305,0) -- Trim left edge to cursor
    end

    reaper.Undo_EndBlock("Trim Left Edge by Nudge", -1)
end

trim_left()

