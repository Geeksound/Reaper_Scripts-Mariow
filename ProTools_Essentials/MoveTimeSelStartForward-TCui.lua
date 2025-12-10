--[[
@description Move Time Selection START Forward by Nudge Value (TimecodeUI)
@version 1.0
@author Mariow
@changelog
    v1.0 (2025-12-09)
    - Initial release: moves the start of the Time Selection forward according to TimecodeUI nudge value
@provides
    [main] ProTools_Essentials/MoveTimeSelectionStartForward-TCui.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags editing, timesel, nudge, transport, forward, (protools-like)
@about
    # Move Time Selection START Forward by Nudge Value
    
    Moves the **start point** of the current Time Selection forward
    according to the nudge value defined in the shared **TimecodeUI** panel.
    
    ## 🟦 Timecode Input (Shared Setting)
    - Namespace: **"TimecodeUI"**
    - Key: **"tc"**
    - Format: `HH:MM:SS:FF` (frames, 25 fps)
    
    ## 🟩 Usage
    - Moves the start of the Time Selection forward (+1).
    - Prevents the start from moving past the end of the selection.
    - Undo supported via REAPER's undo system.
    
    ## 🔗 Part of the ProTools_Essentials Suite
    Works alongside:
    
    - MoveTimeSelEndForward / MoveTimeSelEndBackward  
    - Grow/Shrink Time Selection  
    - Razor Area movement scripts  
    - Nudge Forward / Backward  
    - Timecode UI (ImGui)  
    
    These scripts provide a unified, Pro Tools–inspired editing workflow in REAPER.
--]]


-------------------------------------
-- Lire le timecode depuis ExtState
-------------------------------------
local function read_tc()
    local tc = reaper.GetExtState("TimecodeUI", "tc")
    if not tc or tc == "" then return 0 end

    local h, m, s, f = tc:match("(%d+):(%d+):(%d+):(%d+)")
    if not h then return 0 end

    local fps = 25
    local total_seconds = h*3600 + m*60 + s + f/fps

    return total_seconds
end

-------------------------------------
-- Déplacer start de la time selection
-------------------------------------
local function move_timesel_start(direction)
    -- direction = -1 for backward, +1 for forward
    
    local delta = read_tc()
    if delta == 0 then return end

    reaper.Undo_BeginBlock()

    local start, stop = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)

    -- S’il n’y a pas de time selection, ne rien faire
    if start == stop then 
        reaper.Undo_EndBlock("Move Time Selection Start - No TS", -1)
        return 
    end

    -- Déplacement
    local new_start = start + delta * direction

    -- Assurer que start ne dépasse pas stop
    if new_start > stop then
        new_start = stop
    end

    reaper.GetSet_LoopTimeRange(true, false, new_start, stop, false)

    local action_name = (direction > 0) and "Move TS Start Forward" or "Move TS Start Backward"
    reaper.Undo_EndBlock(action_name, -1)
end


----------------------------------------------------
-- CONFIG : direction
-- direction = -1 → backward
-- direction = +1 → forward
----------------------------------------------------
local direction = 1   -- ← VERSION FORWARD

move_timesel_start(direction)

