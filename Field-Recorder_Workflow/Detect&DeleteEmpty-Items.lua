--[[
@description Detect&DeleteEmpty-Items
@version 1.0
@author Mariow
@license MIT
@changelog
  v1.0 (2025-06-08)
  - Initial release
@provides
  [main] Field-Recorder_Workflow/Detect&DeleteEmpty-Items.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags items editing
@about
  # Detect&DeleteEmpty-Items

  Variation of DetectEmpty-Items. During recording, sometimes empty tracks are created.
  During conformation, it may be useful to delete them for cleaning.

  This script was developed with the help of GitHub Copilot.
--]]

reaper.Undo_BeginBlock()

local project = 0
local threshold_db = -90
local threshold_amp = 10 ^ (threshold_db / 20)
local num_items = reaper.CountMediaItems(project)

for i = num_items - 1, 0, -1 do -- on boucle à l'envers pour éviter les décalages lors de suppression
local item = reaper.GetMediaItem(project, i)
local take = reaper.GetActiveTake(item)

if take and not reaper.TakeIsMIDI(take) then
local source = reaper.GetMediaItemTake_Source(take)
local samplerate = reaper.GetMediaSourceSampleRate(source)
local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
local nch = reaper.GetMediaSourceNumChannels(source)
local samples = 2048
local accessor = reaper.CreateTakeAudioAccessor(take)

local is_silent = true
local check_points = 3

for s = 0, check_points - 1 do
local pos = (item_len / check_points) * s
local buffer = reaper.new_array(samples * nch)
reaper.GetAudioAccessorSamples(accessor, samplerate, nch, pos, samples, buffer)

for j = 1, samples * nch do
if math.abs(buffer[j]) > threshold_amp then
is_silent = false
break
end
end

if not is_silent then break end
end

reaper.DestroyAudioAccessor(accessor)

if is_silent then
reaper.DeleteTrackMediaItem(reaper.GetMediaItem_Track(item), item)
end
end
end

reaper.UpdateArrange()
reaper.Undo_EndBlock("Delete Empty Items", -1)

