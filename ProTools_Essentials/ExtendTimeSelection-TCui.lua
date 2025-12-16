--[[
@description Extend Time Selection (reads timecode from PRE-POST-ROLL ImGui panel)
@version 1.0
@author Mariow
@changelog
    v1.0 (2025-12-09)
    - Initial release (extends current Time Selection using TimecodeUI value)
@provides
    [main] ProTools_Essentials/ExtendTimeSelection-TCui.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags editing, time selection, nudge, transport, (protools-like)
@about
    # Extend Time Selection (ProTools-like)
    
    This script extends the current **Time Selection** in REAPER according to a duration
    defined by the companion **Unified PRE-POST-ROLL + Timecode UI (ImGui)** panel.
    
    The **left edge** of the Time Selection is moved **backward**, and the **right edge**
    is moved **forward** by the specified timecode duration.
    
    ## 🟦 Timecode Input (Shared Setting)
    The extension amount is read from a shared ExtState:
    
    - Namespace: **"TimecodeUI"**  
    - Key: **"tc"**  
    - Format: `HH:MM:SS:FF` (frames based; currently 25 fps)
    
    This value is maintained by the **PRE-POST-ROLL + Timecode UI (No Title, Draggable)**
    script, ensuring consistent durations across all ProTools-like navigation scripts.
    
    ## 🟩 Usage
    - Existing Time Selection → extended on both sides by the timecode duration.  
    - No Time Selection → script does nothing.  
    - Undo is supported via REAPER's undo system.
    
    ## 🔗 Part of the ProTools_Essentials Suite
    Works in conjunction with:
    
    - Extend Razor Areas  
    - Nudge Forward / Backward  
    - Nudge Forward ×10 / Backward ×10  
    - PRE-POST-ROLL + Timecode UI (ImGui)  
    - Set_Rolls_And_Nudge_Settings  
    - Other ProTools-like transport and editing tools
    
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

local function extend_ts()
    local delta = read_tc()
    if delta == 0 then return end

    local start_ts, end_ts = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
    if start_ts == end_ts then return end

    reaper.Undo_BeginBlock()

    -- LEFT BACKWARD
    local new_start = start_ts - delta

    -- RIGHT FORWARD
    local new_end = end_ts + delta

    -- (aucune inversion possible, on élargit)

    reaper.GetSet_LoopTimeRange(true, false, new_start, new_end, false)

    reaper.Undo_EndBlock("Extend Time Selection", -1)
end

extend_ts()

