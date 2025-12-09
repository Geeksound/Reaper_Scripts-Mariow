--[[
@description Move Razor Areas Forward by Nudge Value (TimecodeUI)
@version 1.0
@author Mariow
@changelog
    v1.0 (2025-12-09)
    - Initial release (moves all Razor Areas forward using TimecodeUI nudge value)
@provides
    [main] ProTools_Essentials/MoveRazorAreaForward-TCui.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags editing, razor, nudge, items, transport, (protools-like)
@about
    # Move Razor Areas Forward by Nudge Value (ProTools-like)
    
    This script moves all **Razor Areas** forward in REAPER according to the nudge value
    defined in the shared **TimecodeUI** panel.
    
    If no Razor Areas exist, the script automatically converts the current **Time Selection**
    into Razor Areas and applies the movement.
    
    ## 🟦 Timecode Input (Shared Setting)
    - Namespace: **"TimecodeUI"**
    - Key: **"tc"**
    - Format: `HH:MM:SS:FF` (frames based; currently 25 fps)
    
    ## 🟩 Usage
    - Moves each Razor Area forward by the nudge value.  
    - If no Razor Areas exist, creates them from Time Selection first.  
    - Undo supported via REAPER's undo system.
    
    ## 🔗 Part of the ProTools_Essentials Suite
    Works in conjunction with:
    
    - Extend/Reduce Razor Areas  
    - Grow/Shrink Left & Right Edges  
    - Nudge Forward / Nudge Backward  
    - PRE-POST-ROLL + Timecode UI (ImGui)  
    - Set_Rolls_And_Nudge_Settings  
    
    Together, these scripts provide a unified, Pro Tools–inspired editing workflow in REAPER.
--]]


---------------------------------
-- Lire le timecode
---------------------------------
local function read_tc()
    local tc = reaper.GetExtState("TimecodeUI","tc")
    if not tc or tc == "" then return 0 end

    local h, m, s, f = tc:match("(%d+):(%d+):(%d+):(%d+)")
    if not h then return 0 end

    local fps = 25
    return h*3600 + m*60 + s + f/fps
end

---------------------------------
-- Lire les Razor Areas
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
                parts[#parts+1] = part
            end

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

---------------------------------
-- Appliquer modifications Razor
---------------------------------
local function apply_razor_changes(areas)
    for _, a in ipairs(areas) do
        local str = string.format("%.12f %.12f %s", a.start, a.endp, a.guid)
        reaper.GetSetMediaTrackInfo_String(a.track, "P_RAZOREDITS", str, true)
    end
end

---------------------------------
-- Créer Razor Areas depuis Time Selection si aucune n'existe
---------------------------------
local function create_razor_from_timesel()
    local start_ts, end_ts = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
    if start_ts == end_ts then return end -- pas de time selection

    local track_count = reaper.CountTracks(0)
    for i = 0, track_count - 1 do
        local tr = reaper.GetTrack(0, i)
        local guid = reaper.BR_GetMediaTrackGUID(tr)
        -- Crée Razor Area avec start et end de la TS
        local str = string.format("%.12f %.12f %s", start_ts, end_ts, guid)
        reaper.GetSetMediaTrackInfo_String(tr, "P_RAZOREDITS", str, true)
    end
end

---------------------------------
-- Déplacement Razor Forward
---------------------------------
local function move_forward()
    local delta = read_tc()
    if delta == 0 then return end

    local areas = get_razor_areas()

    -- Crée Razor Areas depuis TS si aucune
    if #areas == 0 then
        create_razor_from_timesel()
        areas = get_razor_areas()
    end

    if #areas == 0 then return end -- rien à déplacer

    reaper.Undo_BeginBlock()

    for _, a in ipairs(areas) do
        a.start = a.start + delta
        a.endp  = a.endp  + delta
    end

    apply_razor_changes(areas)

    reaper.Undo_EndBlock("Move Razor Areas Forward", -1)
end

move_forward()

