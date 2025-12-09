--[[
@description Extend Razor Areas (reads timecode from PRE-POST-ROLL ImGui panel)
@version 1.0
@author Mariow
@changelog
    v1.0 (2025-12-09)
    - Initial release (extends Razor Areas based on TimecodeUI value; converts Time Selection if none exist)
@provides
    [main] ProTools_Essentials/ExtendRazor-TCui.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags editing, razor, time selection, nudge, transport, (protools-like)
@about
    # Extend Razor Areas (ProTools-like)
    
    This script extends existing **Razor Areas** in REAPER according to a duration
    defined by the companion **Unified PRE-POST-ROLL + Timecode UI (ImGui)** panel.
    If no Razor Areas exist, it converts the current **Time Selection** into a Razor Area
    before extending.
    
    ## 🟦 Timecode Input (Shared Setting)
    The extension amount is read from a shared ExtState:
    
    - Namespace: **"TimecodeUI"**  
    - Key: **"tc"**  
    - Format: `HH:MM:SS:FF` (frames based; currently 25 fps)
    
    This value is maintained by the **PRE-POST-ROLL + Timecode UI (No Title, Draggable)**
    script, ensuring consistent durations across all ProTools-like navigation scripts.
    
    ## 🟩 Usage
    - Existing Razor Areas → left edge moves backward, right edge moves forward by the timecode duration.  
    - No Razor Areas → current Time Selection is converted into a Razor Area, then extended.  
    - Undo is supported via REAPER's undo system.
    
    ## 🔗 Part of the ProTools_Essentials Suite
    Works in conjunction with:
    
    - Nudge Forward / Backward  
    - Nudge Forward ×10 / Backward ×10  
    - PRE-POST-ROLL + Timecode UI (ImGui)  
    - Set_Rolls_And_Nudge_Settings  
    - Other ProTools-like transport and editing tools
    
    Together, these scripts provide a unified, Pro Tools–inspired editing workflow in REAPER.
--]]


---------------------------------
-- Lire le timecode
---------------------------------
local function read_tc()
    local tc = reaper.GetExtState("TimecodeUI", "tc")
    if not tc or tc == "" then return 0 end
    local h, m, s, f = tc:match("(%d+):(%d+):(%d+):(%d+)")
    if not h then return 0 end
    local fps = 25
    return h*3600 + m*60 + s + f/fps
end

---------------------------------
-- Lire tous les Razor Areas
---------------------------------
local function get_razor_areas()
    local areas = {}
    local track_count = reaper.CountTracks(0)

    for i = 0, track_count - 1 do
        local tr = reaper.GetTrack(0, i)
        local ok, str = reaper.GetSetMediaTrackInfo_String(tr, "P_RAZOREDITS", "", false)

        if ok and str ~= "" then
            local parts = {}
            for part in str:gmatch("([^%s]+)") do
                parts[#parts + 1] = part
            end

            local idx = 1
            while idx <= #parts do
                local start_pos = tonumber(parts[idx]); idx = idx + 1
                local end_pos   = tonumber(parts[idx]); idx = idx + 1
                local guid      = parts[idx]; idx = idx + 1

                areas[#areas + 1] = {
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

---------------------------------
-- Convertir la Time Selection en Razor Area
---------------------------------
local function convert_ts_to_razor()
    local start_ts, end_ts = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
    if start_ts == end_ts then return false end -- pas de TS → rien à faire

    local track_count = reaper.CountTracks(0)
    if track_count == 0 then return false end

    for i = 0, track_count - 1 do
        local tr = reaper.GetTrack(0, i)
        local guid = "TSRA"
        local str = string.format("%.12f %.12f %s", start_ts, end_ts, guid)
        reaper.GetSetMediaTrackInfo_String(tr, "P_RAZOREDITS", str, true)
    end

    return true
end

---------------------------------
-- Écrire les Razor Areas
---------------------------------
local function apply_razor_changes(areas)
    for _, a in ipairs(areas) do
        local str = string.format("%.12f %.12f %s", a.start, a.endp, a.guid)
        reaper.GetSetMediaTrackInfo_String(a.track, "P_RAZOREDITS", str, true)
    end
end

---------------------------------
-- Extend Razor
---------------------------------
local function extend_razor()
    local delta = read_tc()
    if delta == 0 then return end

    local areas = get_razor_areas()

    -- Si aucun Razor → convertir Time Selection
    if #areas == 0 then
        local ok = convert_ts_to_razor()
        if not ok then return end
        areas = get_razor_areas() -- relire les Razor créés
    end

    if #areas == 0 then return end

    reaper.Undo_BeginBlock()

    for _, a in ipairs(areas) do
        
        -- LEFT backward
        local new_left = a.start - delta
        if new_left > a.endp then new_left = a.endp end
        a.start = new_left

        -- RIGHT forward
        local new_right = a.endp + delta
        if new_right < a.start then new_right = a.start end
        a.endp = new_right
    end

    apply_razor_changes(areas)

    reaper.Undo_EndBlock("Extend Razor Areas", -1)
end

extend_razor()

