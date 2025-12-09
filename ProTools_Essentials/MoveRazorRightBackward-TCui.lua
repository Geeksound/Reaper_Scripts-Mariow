--[[
@description Move RIGHT Edge of Razor Areas Backward by Nudge Value (TimecodeUI)
@version 1.0
@author Mariow
@changelog
    v1.0 (2025-12-09)
    - Initial release (moves right edge of Razor Areas backward using TimecodeUI nudge value)
@provides
    [main] ProTools_Essentials/MoveRazorRightBackward-TCui.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags editing, razor, nudge, items, transport, (protools-like)
@about
    # Move RIGHT Edge of Razor Areas Backward by Nudge Value (ProTools-like)
    
    This script moves the **right edge** of all Razor Areas backward according to the
    nudge value defined in the shared **TimecodeUI** panel.
    
    If no Razor Areas exist, the script automatically converts the current **Time Selection**
    into Razor Areas and applies the movement.
    
    ## 🟦 Timecode Input (Shared Setting)
    - Namespace: **"TimecodeUI"**
    - Key: **"tc"**
    - Format: `HH:MM:SS:FF` (frames based; currently 25 fps)
    
    ## 🟩 Usage
    - Moves the right edge of each Razor Area backward by the nudge value.  
    - If no Razor Areas exist, creates them from Time Selection first.  
    - Undo supported via REAPER's undo system.
    
    ## 🔗 Part of the ProTools_Essentials Suite
    Works in conjunction with:
    
    - MoveRazorAreaForward / MoveRazorAreaBackward  
    - MoveRazorLeftForward / MoveRazorLeftBackward  
    - Extend/Reduce Razor Areas  
    - Grow/Shrink Left & Right Edges  
    - Nudge Forward / Nudge Backward  
    - PRE-POST-ROLL + Timecode UI (ImGui)  
    
    Together, these scripts provide a unified, Pro Tools–inspired editing workflow in REAPER.
--]]


local function read_tc()
    local tc = reaper.GetExtState("TimecodeUI", "tc")
    if not tc or tc == "" then return 0 end
    local h, m, s, f = tc:match("(%d+):(%d+):(%d+):(%d+)")
    if not h then return 0 end
    local fps = 25
    return h*3600 + m*60 + s + f/fps
end

-- Parse all razor areas
local function get_razor_areas()
    local areas = {}
    local track_count = reaper.CountTracks(0)

    for i = 0, track_count - 1 do
        local tr = reaper.GetTrack(0, i)
        local ok, str = reaper.GetSetMediaTrackInfo_String(tr, "P_RAZOREDITS", "", false)

        if ok and str ~= "" then
            local parts = {}
            for part in str:gmatch("([^%s]+)") do parts[#parts+1] = part end

            local idx = 1
            while idx <= #parts do
                local start_pos = tonumber(parts[idx]); idx = idx + 1
                local end_pos   = tonumber(parts[idx]); idx = idx + 1
                local guid      = parts[idx]; idx = idx + 1

                areas[#areas+1] = {
                    track = tr,
                    start = start_pos,
                    endp  = end_pos,
                    guid  = guid
                }
            end
        end
    end

    return areas
end

local function apply_razor_changes(areas)
    for _, a in ipairs(areas) do
        local str = string.format("%.12f %.12f %s", a.start, a.endp, a.guid)
        reaper.GetSetMediaTrackInfo_String(a.track, "P_RAZOREDITS", str, true)
    end
end

-- Convert Time Selection into Razor Areas if none exist
local function create_razor_from_time_selection()
    local start_ts, end_ts = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
    if start_ts == end_ts then return false end -- pas de TS

    local track_count = reaper.CountTracks(0)
    if track_count == 0 then return false end

    local guid = "{00000000-0000-0000-0000-000000000000}"

    for i = 0, track_count - 1 do
        local tr = reaper.GetTrack(0, i)
        local str = string.format("%.12f %.12f %s", start_ts, end_ts, guid)
        reaper.GetSetMediaTrackInfo_String(tr, "P_RAZOREDITS", str, true)
    end

    return true
end

local function move_right(direction)
    local delta = read_tc()
    if delta == 0 then return end

    -- Lire Razor Areas existants
    local areas = get_razor_areas()

    -- Si aucun Razor Area → créer depuis la Time Selection
    if #areas == 0 then
        local created = create_razor_from_time_selection()
        if not created then return end -- pas de TS → rien à faire
        areas = get_razor_areas()
    end

    if #areas == 0 then return end

    reaper.Undo_BeginBlock()

    for _, a in ipairs(areas) do
        local new_right = a.endp + delta * direction
        if new_right < a.start then new_right = a.start end
        a.endp = new_right
    end

    apply_razor_changes(areas)

    reaper.Undo_EndBlock("Move Razor Right Backward", -1)
end

-- BACKWARD
local direction = -1
move_right(direction)

