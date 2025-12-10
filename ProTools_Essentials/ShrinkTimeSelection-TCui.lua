--[[
@description Shrink Time Selection by Nudge Value (TimecodeUI)
@version 1.0
@author Mariow
@changelog
    v1.0 (2025-12-09)
    - Initial release (reduces time selection using TimecodeUI nudge value)
@provides
    [main] ProTools_Essentials/ShrinkTimeSelection-TCui.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags editing, timesel, nudge, transport, (protools-like)
@about
    # Shrink Time Selection by Nudge Value (ProTools-like)
    
    This script reduces the current **Time Selection** in REAPER by moving the **left edge forward**
    and the **right edge backward** according to the nudge value defined in the companion **TimecodeUI** panel.
    
    ## 🟦 Timecode Input (Shared Setting)
    - Namespace: **"TimecodeUI"**
    - Key: **"tc"**
    - Format: `HH:MM:SS:FF` (frames based; currently 25 fps)
    
    Using this shared ExtState ensures consistent nudge behavior across all related scripts.
    
    ## 🟩 Usage
    - Only affects the **current Time Selection**.  
    - Left edge moves forward by the nudge value.  
    - Right edge moves backward by the nudge value.  
    - Prevents inversion: start will never surpass end.  
    - Undo is fully supported via REAPER's undo system.
    
    ## 🔗 Part of the ProTools_Essentials Suite
    Works in conjunction with:
    
    - Extend/Reduce Razor Areas  
    - Grow/Shrink Left & Right Edges  
    - Nudge Forward / Nudge Backward  
    - PRE-POST-ROLL + Timecode UI (ImGui)  
    - Set_Rolls_And_Nudge_Settings  
    
    Together, these scripts provide a unified, Pro Tools–inspired editing workflow in REAPER.
--]]


-- Effacer tous les Razor Areas
reaper.Main_OnCommand(42406, 0)

local function read_tc()
    local tc = reaper.GetExtState("TimecodeUI", "tc")
    if not tc or tc == "" then return 0 end
    local h, m, s, f = tc:match("(%d+):(%d+):(%d+):(%d+)")
    if not h then return 0 end
    local fps = 25
    return h*3600 + m*60 + s + f/fps
end

local function shrink_ts()
    local delta = read_tc()
    if delta == 0 then return end

    local start_ts, end_ts = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
    if start_ts == end_ts then return end

    reaper.Undo_BeginBlock()

    -- LEFT FORWARD
    local new_start = start_ts + delta

    -- RIGHT BACKWARD
    local new_end = end_ts - delta

    -- éviter l’inversion
    if new_start > new_end then
        new_start = new_end
    end

    reaper.GetSet_LoopTimeRange(true, false, new_start, new_end, false)

    reaper.Undo_EndBlock("Shrink Time Selection", -1)
end

shrink_ts()

