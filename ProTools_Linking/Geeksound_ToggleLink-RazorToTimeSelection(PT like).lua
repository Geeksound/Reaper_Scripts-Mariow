--[[
@description Toggle Link Razor Edit ↔ Time Selection (ProTools-like)
@version 1.0
@author Mariow
@changelog
  v1.0 (2026-03-14)
  - Initial release
  - Toggle linkage between Razor Edits and Time Selection
  - Automatically updates Time Selection to match Razor Edit area
@provides
  [main] ProTools_Linking/Geeksound_ToggleLink-RazorToTimeSelection(PT like).lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags razor edit, time selection, link, toggle, editing, (protools-like)
@about
@about
  # Toggle Link Razor Edit ↔ Time Selection (ProTools-like)

  This script links Razor Edit areas with the global Time Selection.

  It is normally started automatically at REAPER startup
  by the companion script:

    Geeksound_Startup-RazorLinks

  Once enabled, it remains active in the background and monitors
  Razor Edit changes during the session.

  In normal use, you do not need to run this script manually,
  unless you want to toggle the link ON or OFF from a toolbar button.

  Designed for editing workflows where Razor Edits are used as
  the primary selection tool, providing a Pro Tools–like behavior.
--]]

local SECTION = "Mariow_Scripts"
local KEY     = "RazorTimeSelLink"

-- récupération toolbar toggle
local _, _, sectionID, cmdID = reaper.get_action_context()

-- lecture de l'état actuel
local state = reaper.GetExtState(SECTION, KEY)

-- toggle ON/OFF
if state == "" or state == "OFF" then
    reaper.SetExtState(SECTION, KEY, "ON", false)
    if sectionID and cmdID then
        reaper.SetToggleCommandState(sectionID, cmdID, 1)
        reaper.RefreshToolbar2(sectionID, cmdID)
    end
else
    reaper.SetExtState(SECTION, KEY, "OFF", false)
    if sectionID and cmdID then
        reaper.SetToggleCommandState(sectionID, cmdID, 0)
        reaper.RefreshToolbar2(sectionID, cmdID)
    end
end

-- fonction qui met à jour la Time Selection selon Razor Edits
local function update_timesel()
    if reaper.GetExtState(SECTION, KEY) ~= "ON" then return end

    local ts_start, ts_end = math.huge, -1
    local track_count = reaper.CountTracks(0)

    for t = 0, track_count-1 do
        local track = reaper.GetTrack(0, t)
        local _, razor_str = reaper.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", "", false)

        if razor_str and razor_str ~= "" then
            for s, e in string.gmatch(razor_str, '([%d%.%-]+) ([%d%.%-]+) %S+') do
                local rs, re = tonumber(s), tonumber(e)
                if rs < ts_start then ts_start = rs end
                if re > ts_end then ts_end = re end
            end
        end
    end

    if ts_start < ts_end then
        reaper.GetSet_LoopTimeRange(true, false, ts_start, ts_end, false)
    end

    reaper.defer(update_timesel)
end

update_timesel()
