--[[
@description 6PointsToEnvelope at ITEM SELECTED or Time Selection or Razor – Fast Mouse Editing (Item-aware)
@version 1.3
@author Mariow
@changelog
  v1.3 (2025-12-XX)
  - NEW: If an item is selected, TS follows the item’s start/end (ignores Razor)
  - Respects existing time-selection (never overwrites it)
  - Razor → Time Selection fallback only when no TS and no selected item
  - Still forces operations to apply on the initially selected track
  - Razor areas are always cleared for safety
  
@provides
  [main] Protools_Edit/Create-6PointsEnveloppe(PT).lua
  
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow

@tags editing, envelope, automation, items, razor, timesel, prottools-like, mouse-editing

@about
  # 6 Points to Envelope for Item / Time Selection / Razor (Item-aware)
  Creates six automation points around the edit zone, adapting dynamically to context:
  - **Selected item** → the edit range becomes the item’s start/end  
  - **Existing time selection** → used as-is  
  - **Razor selection** → used only if no item and no time selection  
  Ensures ProTools-like precision for fast mouse-based envelope editing while keeping 
  behavior predictable and safe (Razor areas are cleared after processing).
--]]


------------------------------------------------------------
-- Try to create TS from selected items on the initial track
------------------------------------------------------------
local function itemsToTimeSel(track)

    -- check existing TS
    local ts_start, ts_end = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
    if ts_end > ts_start then
        return true -- TS already exists, do nothing (respect user's TS)
    end

    -- get item count on this track
    local cnt = reaper.CountTrackMediaItems(track)
    local min_start, max_end = math.huge, -1
    local found_selected = false

    for i = 0, cnt-1 do
        local it = reaper.GetTrackMediaItem(track, i)
        if reaper.IsMediaItemSelected(it) then
            found_selected = true
            local pos = reaper.GetMediaItemInfo_Value(it, "D_POSITION")
            local len = reaper.GetMediaItemInfo_Value(it, "D_LENGTH")
            local it_start = pos
            local it_end = pos + len

            if it_start < min_start then min_start = it_start end
            if it_end   > max_end  then max_end  = it_end  end
        end
    end

    -- no selected item
    if not found_selected then return false end

    -- create TS from selected item(s)
    reaper.GetSet_LoopTimeRange(true, false, min_start, max_end, false)
    return true
end


------------------------------------------------------------
-- Create Time Selection from Razor Edit (only if no TS)
------------------------------------------------------------
local function razorToTimeSel()

    local ts_start, ts_end = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
    if ts_end > ts_start then
        return false -- TS exists, skip Razor
    end

    local r_st, r_en = math.huge, -1
    for i = 0, reaper.CountTracks(0)-1 do
        local tr = reaper.GetTrack(0, i)
        local ok, areas = reaper.GetSetMediaTrackInfo_String(tr, "P_RAZOREDITS", "", false)
        if ok and areas ~= "" then
            for a_start, a_end, guid in string.gmatch(areas, "(%S+) (%S+) (%S+)") do
                a_start = tonumber(a_start)
                a_end   = tonumber(a_end)
                if a_start < r_st then r_st = a_start end
                if a_end   > r_en then r_en = a_end end
            end
        end
    end

    if r_en == -1 then return false end

    reaper.GetSet_LoopTimeRange(true, false, r_st, r_en, false)
    return true
end


------------------------------------------------------------
-- Clear Razor Areas
------------------------------------------------------------
local function clearAllRazors()
    for i = 0, reaper.CountTracks(0)-1 do
        local tr = reaper.GetTrack(0, i)
        reaper.GetSetMediaTrackInfo_String(tr, "P_RAZOREDITS", "", true)
    end
end


------------------------------------------------------------
-- Keep ONLY the initial selected track active
------------------------------------------------------------
local function lockInitialTrack()
    local selected = reaper.CountSelectedTracks(0)
    if selected == 0 then return nil end

    local initial_track = reaper.GetSelectedTrack(0, 0)

    for i = 0, reaper.CountTracks(0)-1 do
        local tr = reaper.GetTrack(0, i)
        reaper.SetTrackSelected(tr, false)
    end

    reaper.SetTrackSelected(initial_track, true)
    reaper.Main_OnCommand(40914, 0) -- set as last touched

    return initial_track
end


------------------------------------------------------------
-- MAIN
------------------------------------------------------------
reaper.Undo_BeginBlock()

local initial_track = lockInitialTrack()
if not initial_track then
    reaper.Undo_EndBlock("6PointsToEnvelope (FAILED - no track)", -1)
    return
end

-- 1) TS from selected items first (only if no TS)
local ts_from_items = itemsToTimeSel(initial_track)

-- 2) If still no TS → use Razor
if not ts_from_items then
    razorToTimeSel()
end

-- 3) Clear Razor to avoid wrong envelope target
clearAllRazors()

------------------------------------------------------------
-- ORIGINAL ACTION SEQUENCE
------------------------------------------------------------

reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_SELITEMSUNDEDCURSELTX"), 0)
reaper.Main_OnCommand(41866, 0)
reaper.Main_OnCommand(reaper.NamedCommandLookup("_BR_INSERT_2_ENV_POINT_TIME_SEL"), 0)
reaper.Main_OnCommand(40630, 0)

reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_MOVECUR5MSLEFT"), 0)
reaper.Main_OnCommand(40625, 0)
reaper.Main_OnCommand(40631, 0)

reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_MOVECUR5MSRIGHT"), 0)
reaper.Main_OnCommand(40626, 0)

reaper.Main_OnCommand(reaper.NamedCommandLookup("_BR_INSERT_2_ENV_POINT_TIME_SEL"), 0)

reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_MOVECUR5MSRIGHT"), 0)
reaper.Main_OnCommand(40626, 0)
reaper.Main_OnCommand(40630, 0)

reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_MOVECUR5MSLEFT"), 0)
reaper.Main_OnCommand(40625, 0)

reaper.Main_OnCommand(reaper.NamedCommandLookup("_BR_INSERT_2_ENV_POINT_TIME_SEL"), 0)
reaper.Main_OnCommand(40289, 0)
reaper.Main_OnCommand(40635, 0)

reaper.Undo_EndBlock("6PointsToEnvelope (TS / Razor / Item)", -1)

