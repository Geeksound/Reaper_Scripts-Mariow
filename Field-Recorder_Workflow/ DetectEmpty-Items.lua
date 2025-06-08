--[[
@description DetectEmpty-Items
@version 1.0
@author Mariow
@license MIT
@changelog
  v1.0 (2025-06-08)
  - Initial release
@provides
  [main] Editing/DetectEmpty-Items.lua
  [main] Field-Recorder_Workflow/DetectEmpty-Items.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags items editing
@about
  # DetectEmpty-Items

  Sometimes in Fieldrecorder, tracks are armed but empty.
  During conformation, it may be useful to see them for cleaning.

  This script was developed with the help of GitHub Copilot.
--]]


reaper.Undo_BeginBlock()

local project = 0
local threshold_db = -90
local threshold_amp = 10 ^ (threshold_db / 20)
local num_items = reaper.CountMediaItems(project)

for i = 0, num_items - 1 do
local item = reaper.GetMediaItem(project, i)
local take = reaper.GetActiveTake(item)

if take and not reaper.TakeIsMIDI(take) then
local source = reaper.GetMediaItemTake_Source(take)
local samplerate = reaper.GetMediaSourceSampleRate(source)
local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
local nch = reaper.GetMediaSourceNumChannels(source)
local samples = 2048 -- plus petit pour plus de vitesse
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
-- Couleur grise
reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", reaper.ColorToNative(100, 100, 100) | 0x1000000)

-- Préfixe £ au nom du take
local orig_name_retval, orig_name = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)
if orig_name and not orig_name:find("^£") then
reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "£" .. orig_name, true)
end
end
end
end

reaper.UpdateArrange()
reaper.Undo_EndBlock("Marquer items silencieux (gris + £)", -1)

