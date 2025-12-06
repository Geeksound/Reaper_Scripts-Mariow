--[[
@description Cut Time on Selected Tracks(Shufflemode)
@version 1.0
@author Mariow/Fernsehmuell
@changelog
  v1.0 (2025-12-06)
  - Cuts time only on selected tracks
  - Supports Razor Area or Time Selection
@provides
  [main] Protools_Edit/Cut-Time-Per-Track(Shuffle).lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags editing, time, cut, razor, tracks.
@about
  # Cut Time on Selected Tracks — Fernsehmuell style
  Cuts a selected time range only on tracks currently selected.
  Supports:
  - Razor Areas
  - Time Selection
--]]

local reaper = reaper

-- Helpers
local function GetRulerMode() return reaper.GetSetProjectInfo(0,"PROJECT_TIMEMODE",0,false) end
local function ToSeconds(val,mode)
    if mode==0 or mode==2 then return val end
    if mode==3 then return val / reaper.GetSetProjectInfo(0,"PROJECT_SRATE",0,false) end
    if mode==4 or mode==5 then return val / reaper.TimeMap_curFrameRate(0) end
    if mode==1 or mode==6 then return reaper.TimeMap2_beatsToTime(0,val) end
    return val
end

-- Razor Area detection
local function GetRazorBounds()
    local min_t,max_t=math.huge,-math.huge
    local found=false
    for i=0,reaper.CountTracks(0)-1 do
        local tr=reaper.GetTrack(0,i)
        local ok,str=reaper.GetSetMediaTrackInfo_String(tr,"P_RAZOREDITS","",false)
        if ok and str~="" then
            found=true
            for s,e in string.gmatch(str,"(%S+) (%S+) %S+") do
                s=tonumber(s); e=tonumber(e)
                if s<min_t then min_t=s end
                if e>max_t then max_t=e end
            end
        end
    end
    if found then return min_t,max_t end
    return nil,nil
end

-- Clear IN/OUT markers
local function clear_all_in_and_out_markers()
    reaper.Main_OnCommand(40635,0)
    reaper.SetProjExtState(0,"Fernsehmuell","StartpointIsZero","False")
    reaper.SetProjExtState(0,"Fernsehmuell","End_Point_before_Start_Point","")
    local retval, marker_count, _ = reaper.CountProjectMarkers(0)
    for i=marker_count-1,0,-1 do
        local index,isrgn,pos,rgnend,name,markrgnindex = reaper.EnumProjectMarkers2(0,i)
        if name==" [ in" or name==" out ]" then
            reaper.DeleteProjectMarkerByIndex(0,index-1)
        end
    end
end

-- Move cursor to IN
local function goto_in(in_pos,out_pos)
    local playstate=reaper.GetPlayState()
    if playstate==1 then reaper.Main_OnCommand(1016,0) end
    if in_pos==0.0 and out_pos==0.0 then
        reaper.Main_OnCommand(40042,0)
    else
        if in_pos~=out_pos then
            reaper.Main_OnCommand(40630,0)
        else
            local actpos=reaper.GetCursorPosition()
            reaper.MoveEditCursor(in_pos-actpos,0)
        end
    end
end

-- Main Cut function
local function main_cut(in_pos,out_pos)
    reaper.Undo_BeginBlock()

    local ripple_all = reaper.GetToggleCommandState(40311)
    local ripple_track = reaper.GetToggleCommandState(40310)

    goto_in(in_pos,out_pos)

    reaper.Main_OnCommand(40309,0) -- ripple off
    reaper.Main_OnCommand(40289,0) -- unselect all items
    reaper.Main_OnCommand(40718,0) -- select items on selected tracks in time selection

    if reaper.CountSelectedMediaItems(0)>0 then
        reaper.Main_OnCommand(40312,0) -- remove selected area of items
    end

    local duration = out_pos - in_pos
    for t=1,reaper.CountSelectedTracks(0) do
        local track = reaper.GetSelectedTrack(0,t-1)
        local item_count = reaper.GetTrackNumMediaItems(track)
        for i=1,item_count do
            local item = reaper.GetTrackMediaItem(track,i-1)
            local pos = reaper.GetMediaItemInfo_Value(item,"D_POSITION")
            if pos>=in_pos then
                reaper.SetMediaItemInfo_Value(item,"D_POSITION",pos-duration)
            end
        end
    end

    -- restore ripple
    reaper.Main_OnCommand(40309,0)
    if ripple_all==1 then reaper.Main_OnCommand(40311,0)
    elseif ripple_track==1 then reaper.Main_OnCommand(40310,0) end

    clear_all_in_and_out_markers()
    reaper.Main_OnCommand(40289,0) -- unselect all

    reaper.Undo_EndBlock("Cut Time (per-track, Fernsehmuell)",-1)
end

-- 🔹 Script execution without GUI
local rz_s, rz_e = GetRazorBounds()
local in_pos, out_pos
if rz_s and rz_e and rz_s~=rz_e then
    in_pos = rz_s
    out_pos = rz_e
else
    local ts_start, ts_end = reaper.GetSet_LoopTimeRange(false,false,0,0,false)
    if ts_start~=ts_end then
        in_pos = ts_start
        out_pos = ts_end
    else
        reaper.ShowMessageBox("No Razor Area or Time Selection found", "Cut Time", 0)
        return
    end
end

main_cut(in_pos,out_pos)

