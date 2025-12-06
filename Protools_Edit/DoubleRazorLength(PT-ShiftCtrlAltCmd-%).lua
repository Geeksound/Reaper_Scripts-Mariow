--[[
@description Double-length of Razor-Area on selected tracks
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-11-26)
  - Initial release
@provides
  [main] Protools_Edit/DoubleRazorLength(PT-ShiftCtrlAltCmd-%).lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags razor edits, tracks, editing, items
@about
  # Double Razor Edit Duration
  Doubles the length of Razor Edits on all selected tracks in REAPER.
  Maintains fade lengths and supports multiple Razor Edit areas per track.
--]]

local track_count = reaper.CountSelectedTracks(0)

for t = 0, track_count-1 do
    local track = reaper.GetSelectedTrack(0, t)
    local _, razor_str = reaper.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", "", false)

    if razor_str and razor_str ~= "" then
        local new_str = ""

        -- La string Razor Edit peut être "start end fade" ou juste "start end"
        for s, e, f in string.gmatch(razor_str, '(%S+) (%S+) (%S*)') do
            local start_time  = tonumber(s)
            local end_time    = tonumber(e)
            local fade_length = tonumber(f) or 0      -- si nil → 0
            local new_end = start_time + (end_time - start_time) * 2
            new_str = new_str .. start_time .. " " .. new_end .. " " .. fade_length .. " "
        end

        -- applique la nouvelle string Razor Edit
        reaper.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", new_str, true)
    end
end

reaper.UpdateArrange()
reaper.Undo_OnStateChange("Double Razor Edit duration")

