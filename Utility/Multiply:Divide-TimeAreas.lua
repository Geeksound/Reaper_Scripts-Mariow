--[[
@description Multiply/Divide TimeAreas (razor-Timesel-loop) with HH:MM:SS:Frames (ReaImGui)
@version 1.0
@author Mariow
@license MIT
@changelog
  v1.0 (2025-11-26)
  - Initial release
@provides
  [main] Utility/MultiplyDivide-TimeAreas.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags utility editing timing razor timesel loops imgui stretch
@about
  # Multiply / Divide Time Areas (ReaImGui)

  A powerful utility for proportionally scaling the duration of:
  - Razor Edit areas
  - Time Selection
  - Loop Points

  Displays all durations in **HH:MM:SS:Frames** and updates them live as you
  adjust the multiplication or division factor.

  Includes:
  - Factor slider + direct numeric input  
  - Independent toggles per time zone  
  - Real-time SMPTE-style preview  
  - ReaImGui-based interface

  Ideal for sound design, dialogue timing, and any workflow requiring
  precise scaling of time-based regions.
--]]


if not reaper.APIExists("ImGui_CreateContext") then
    reaper.MB("ReaImGui is required (install via ReaPack)", "Error", 0)
    return
end

local ctx = reaper.ImGui_CreateContext("Multiply / Divide Time Areas")

-- GUI variables
local applyRazor   = true
local applyTimeSel = true
local applyLoop    = false
local divide       = false
local factor       = 2.0
local fps          = 30 -- frames per second

-- Stored original durations
local razorDur, tsDur, loopDur = 0,0,0

-- Convert seconds -> h,m,s,f
local function sec2hmsf(sec)
    local h = math.floor(sec / 3600)
    local m = math.floor((sec % 3600) / 60)
    local s = math.floor(sec % 60)
    local f = math.floor((sec % 1) * fps)
    return h,m,s,f
end

-- Convert h,m,s,f -> seconds
local function hmsf2sec(h,m,s,f)
    return h*3600 + m*60 + s + f/fps
end

-- Update durations from current project
local function updateDurations()
    -- Razor Edits
    local rs, re = math.huge, -1
    for t=0,reaper.CountTracks(0)-1 do
        local track = reaper.GetTrack(0,t)
        local _, rz = reaper.GetSetMediaTrackInfo_String(track,"P_RAZOREDITS","",false)
        if rz and rz~="" then
            for s,e,_ in string.gmatch(rz,'(%S+) (%S+) (%S*)') do
                local sNum = tonumber(s)
                local eNum = tonumber(e)
                if sNum < rs then rs = sNum end
                if eNum > re then re = eNum end
            end
        end
    end
    razorDur = (re>rs) and (re-rs) or 0

    -- Time Selection
    local ts_start, ts_end = reaper.GetSet_LoopTimeRange(false,false,0,0,false)
    tsDur = (ts_end>ts_start) and (ts_end-ts_start) or 0

    -- Loop Points
    local lp_start, lp_end = reaper.GetSet_LoopTimeRange(false,true,0,0,false)
    loopDur = (lp_end>lp_start) and (lp_end-lp_start) or 0
end

-- Apply factor only to selected zones
local function apply_changes()
    local actual_factor = math.max(factor,1)
    if divide then actual_factor = 1/actual_factor end

    -- Razor Edits
    if applyRazor and razorDur>0 then
        for t=0,reaper.CountTracks(0)-1 do
            local track = reaper.GetTrack(0,t)
            local _, rz = reaper.GetSetMediaTrackInfo_String(track,"P_RAZOREDITS","",false)
            if rz and rz~="" then
                local new_str=""
                for s,e,f in string.gmatch(rz,'(%S+) (%S+) (%S*)') do
                    local start_time = tonumber(s)
                    local end_time   = tonumber(e)
                    local fade_length = tonumber(f) or 0
                    local new_end = start_time + (end_time-start_time)*actual_factor
                    new_str = new_str .. start_time .. " " .. new_end .. " " .. fade_length .. " "
                end
                reaper.GetSetMediaTrackInfo_String(track,"P_RAZOREDITS",new_str,true)
            end
        end
    end

    -- Time Selection
    if applyTimeSel and tsDur>0 then
        local ts_start,_ = reaper.GetSet_LoopTimeRange(false,false,0,0,false)
        local new_end = ts_start + tsDur*actual_factor
        reaper.GetSet_LoopTimeRange(true,false,ts_start,new_end,false)
    end

    -- Loop Points
    if applyLoop and loopDur>0 then
        local lp_start,_ = reaper.GetSet_LoopTimeRange(false,true,0,0,false)
        local new_end = lp_start + loopDur*actual_factor
        reaper.GetSet_LoopTimeRange(true,true,lp_start,new_end,false)
    end

    reaper.UpdateArrange()
    reaper.Undo_OnStateChange("Multiply / Divide selected time areas")
    updateDurations()
end

-- GUI Loop
local function loop()
    updateDurations()
    reaper.ImGui_SetNextWindowSize(ctx,420,240,reaper.ImGui_Cond_FirstUseEver())
    local visible, open = reaper.ImGui_Begin(ctx,"Multiply / Divide Time Areas",true)
    if visible then
        _, applyRazor   = reaper.ImGui_Checkbox(ctx,"Razor Edits",applyRazor)
        _, applyTimeSel = reaper.ImGui_Checkbox(ctx,"Time Selection",applyTimeSel)
        _, applyLoop    = reaper.ImGui_Checkbox(ctx,"Loop Points",applyLoop)
        _, divide       = reaper.ImGui_Checkbox(ctx,"Divide instead of Multiply",divide)

        -- Slider
        _, factor = reaper.ImGui_SliderDouble(ctx,"Factor (slider)",factor,1.0,10.0,"%.2f")
        -- Input direct
        _, factor = reaper.ImGui_InputDouble(ctx,"Factor (input)",factor,0.01)
        factor = math.max(factor,1.0) -- Minimum 1

        -- Affichage hh:mm:ss:frames uniquement pour zones cochées
        local rh,rm,rs,rf = sec2hmsf(applyRazor   and razorDur*factor or razorDur)
        local tsh,tsm,tss,tsf = sec2hmsf(applyTimeSel and tsDur*factor or tsDur)
        local lph,lpm,lps,lpf = sec2hmsf(applyLoop    and loopDur*factor or loopDur)

        reaper.ImGui_Text(ctx,string.format("Razor Edits Duration: %02d:%02d:%02d:%02d",rh,rm,rs,rf))
        reaper.ImGui_Text(ctx,string.format("Time Selection Duration: %02d:%02d:%02d:%02d",tsh,tsm,tss,tsf))
        reaper.ImGui_Text(ctx,string.format("Loop Points Duration: %02d:%02d:%02d:%02d",lph,lpm,lps,lpf))

        if reaper.ImGui_Button(ctx,"Apply") then
            apply_changes()
        end

        reaper.ImGui_End(ctx)
    end

    if open then
        reaper.defer(loop)
    else
        if ctx and reaper.ImGui_DestroyContext then
            reaper.ImGui_DestroyContext(ctx)
        end
    end
end

loop()


