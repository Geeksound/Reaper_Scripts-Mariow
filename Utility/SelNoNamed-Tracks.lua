--[[
@description SelNoNamed-Tracks
@version 1.1
@author Mariow
@license MIT
@changelog
  V1.1 (2025-09-10) 
  - Minor Changes
  v1.0 (2025-06-08)
  - Initial release
@provides
  [main] Utility/SelNoNamed-Tracks.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags tracks editing
@about
  # SelNoNamed-Tracks

  Selects tracks that are not named for different purposes.

  This script was developed with the help of GitHub Copilot.
--]]


reaper.Undo_BeginBlock()
reaper.Main_OnCommand(40297, 0) -- Unselect all tracks

local track_count = reaper.CountTracks(0)
for i = 0, track_count - 1 do
local track = reaper.GetTrack(0, i)
local _, name = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
if name == "" then
reaper.SetTrackSelected(track, true)
end
end

reaper.Undo_EndBlock("Select Tracks without name", -1)

