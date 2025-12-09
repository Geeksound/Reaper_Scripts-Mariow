--[[
@description Move Time Selection END Backward by Nudge Value (TimecodeUI)
@version 1.0
@author Mariow
@changelog
    v1.0 (2025-12-09)
    - Initial release (moves the end of the Time Selection backward using TimecodeUI nudge value)
@provides
    [main] ProTools_Essentials/MoveTimeSelEndBackward-TCui.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags editing, timesel, nudge, transport, (protools-like)
@about
    # Move Time Selection END Backward by Nudge Value
    
    Moves the **end point** of the current Time Selection backward according to the
    nudge value defined in the shared **TimecodeUI** panel.
    
    ## 🟦 Timecode Input (Shared Setting)
    - Namespace: **"TimecodeUI"**
    - Key: **"tc"**
    - Format: `HH:MM:SS:FF` (frames, 25 fps)
    
    ## 🟩 Usage
    - Moves the end of the Time Selection backward by the nudge value.
    - Prevents the end from moving before the start of the selection.
    - Undo supported via REAPER's undo system.
    
    ## 🔗 Part of the ProTools_Essentials Suite
    Works in combination with:
    
    - MoveTimeSelStartForward / MoveTimeSelStartBackward  
    - Grow/Shrink Time Selection  
    - Razor Area movement scripts  
    - Nudge Forward / Backward  
    - Timecode UI (ImGui)  
    
    These scripts provide a unified, Pro Tools–inspired editing workflow in REAPER.
--]]


local function read_tc()
    local tc = reaper.GetExtState("TimecodeUI", "tc")
    if not tc or tc == "" then return 0 end

    local h, m, s, f = tc:match("(%d+):(%d+):(%d+):(%d+)")
    if not h then return 0 end

    local fps = 25
    return h*3600 + m*60 + s + f/fps
end

local function move_timesel_end(direction)
    -- direction = -1 backward, +1 forward

    local delta = read_tc()
    if delta == 0 then return end

    reaper.Undo_BeginBlock()

    local start, stop = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)

    if start == stop then
        reaper.Undo_EndBlock("Move TS End - No TS", -1)
        return
    end

    local new_end = stop + delta * direction

    -- Empêcher end de passer avant start
    if new_end < start then
        new_end = start
    end

    reaper.GetSet_LoopTimeRange(true, false, start, new_end, false)

    reaper.Undo_EndBlock("Move TS End Backward", -1)
end

----------------------------------------------------
-- VERSION BACKWARD
----------------------------------------------------
local direction = -1

move_timesel_end(direction)

