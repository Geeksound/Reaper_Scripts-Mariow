--[[
@description Reduce Razor Areas (Left Forward / Right Backward using TimecodeUI)
@version 1.0
@author Mariow
@changelog
    v1.0 (2025-12-09)
    - Initial release (reduces Razor Areas using TimecodeUI nudge value)
@provides
    [main] ProTools_Essentials/ShrinkRazor-TCui.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags editing, razor, nudge, items, transport, (protools-like)
@about
    # Reduce Razor Areas by Nudge Value (ProTools-like)
    
    This script reduces **Razor Areas** on all tracks:
    
    - **Left edge** moves forward by the nudge value  
    - **Right edge** moves backward by the nudge value
    
    If no Razor Areas exist, the current **Time Selection** is converted into Razor Areas
    to perform the reduction.
    
    ## 🟦 Timecode Input (Shared Setting)
    - Namespace: **"TimecodeUI"**
    - Key: **"tc"**
    - Format: `HH:MM:SS:FF` (frames based; currently 25 fps)
    
    This ensures all Razor Area modifications are synchronized with other nudge-based
    editing tools in the suite.
    
    ## 🟩 Usage
    - Reduces all Razor Areas on all tracks by the configured nudge value.  
    - If no Razor Areas exist → the Time Selection is used as a temporary Razor Area.  
    - Undo is fully supported via REAPER's undo system.
    
    ## 🔗 Part of the ProTools_Essentials Suite
    Works in conjunction with:
    
    - ExtendRazor  
    - Nudge Forward / Nudge Backward  
    - PRE-POST-ROLL + Timecode UI (ImGui)  
    - Set_Rolls_And_Nudge_Settings  
    - Other transport/navigation scripts
    
    Together, these scripts provide a consistent, Pro Tools–inspired editing workflow in REAPER.
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
-- Si aucun Razor Area : convertir la Time Selection
---------------------------------
local function convert_ts_to_razor()
    local start_ts, end_ts = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
    if start_ts == end_ts then return false end     -- pas de time selection → rien à convertir

    local track_count = reaper.CountTracks(0)
    if track_count == 0 then return false end

    for i = 0, track_count - 1 do
        local tr = reaper.GetTrack(0, i)
        local guid = "TSRA"  -- identifiant arbitraire
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
-- Reduce Razor
-- Left forward, Right backward
---------------------------------
local function reduce_razor()
    local delta = read_tc()
    if delta == 0 then return end

    local areas = get_razor_areas()

    -- Si pas de Razor → convertir la Timeselection
    if #areas == 0 then
        local ok = convert_ts_to_razor()
        if not ok then return end
        areas = get_razor_areas() -- relire après création
    end

    if #areas == 0 then return end

    reaper.Undo_BeginBlock()

    for _, a in ipairs(areas) do
        
        -- LEFT forward
        local new_left = a.start + delta
        if new_left > a.endp then new_left = a.endp end
        a.start = new_left

        -- RIGHT backward
        local new_right = a.endp - delta
        if new_right < a.start then new_right = a.start end
        a.endp = new_right
    end

    apply_razor_changes(areas)

    reaper.Undo_EndBlock("Reduce Razor Areas", -1)
end

reduce_razor()

