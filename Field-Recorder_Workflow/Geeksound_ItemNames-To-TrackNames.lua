--[[
@description ItemNames-To-TrackNames
@version 1.0
@author Mariow
@license MIT
@changelog
  v1.0 (2025-06-08)
  - Initial release
@provides
  [main] Field-Recorder_Workflow/ItemNames-To-TrackNames.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags dialogue conformation workflow Fieldrecording Track
@about
  # ItemNames-To-TrackNames

  When items with the same name are organized on the same tracks, it may be useful to rename the track identically.
  - Select item(s) on track(s) and run.
  Useful for some conformation tasks.

  This script was developed with the help of GitHub Copilot.
--]]



function remove_extension(filename)
return filename:match("(.+)%.[^%.]+$") or filename
end

function main()
local item_count = reaper.CountSelectedMediaItems(0)
if item_count == 0 then
reaper.ShowMessageBox("No item selectedé.", "Error", 0)
return
end

local renamed_tracks = {}

for i = 0, item_count - 1 do
local item = reaper.GetSelectedMediaItem(0, i)
local take = reaper.GetActiveTake(item)
if take then
local name = reaper.GetTakeName(take)
name = remove_extension(name)
local track = reaper.GetMediaItem_Track(item)
if track and name and name ~= "" then
renamed_tracks[track] = name -- remplace si plusieurs items sur même piste
end
end
end

-- Appliquer les noms aux pistes
for track, name in pairs(renamed_tracks) do
reaper.GetSetMediaTrackInfo_String(track, "P_NAME", name, true)
end
end

reaper.Undo_BeginBlock()
main()
reaper.Undo_EndBlock("Rename track as Item selected on same track", -1)

