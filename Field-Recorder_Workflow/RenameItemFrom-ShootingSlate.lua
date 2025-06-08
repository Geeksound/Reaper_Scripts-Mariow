--[[
@description RenameItemFrom-ShootingSlate
@version 1.0
@author Mariow
@license MIT
@changelog
  v1.0 (2025-06-08)
  - Initial release
@provides
  [main] Field-Recorder_Workflow/RenameItemFrom-ShootingSlate.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags dialogue conformation workflow Fieldrecording Track rushs raw files matching conforming
@about
  # RenameItemFrom-ShootingSlate

  This script may be used when editing dialogue for pictures and filmmaking.
  - Rename by SCENE/Take - TRACKNAME
  - Rename by TRACKNAME

  This version is inspired & simplified from Rodilab's "Rename Items by Metadata".
  Advanced dialogue Fieldrecorder track viewing, sorting and organizing like in PROTOOLS.

  This script was developed with the help of GitHub Copilot.
--]]



local r = reaper

-- ImGui context
local ctx = r.ImGui_CreateContext('Rename Items')
local FONT = r.ImGui_CreateFont('sans-serif', 14)
r.ImGui_Attach(ctx, FONT)

local option = 1

function Msg(str)
r.ShowConsoleMsg(tostring(str) .. "\n")
end

function GetItemSourcePath(item)
local take = r.GetActiveTake(item)
if not take or r.TakeIsMIDI(take) then return nil, nil end

local chanmode = r.GetMediaItemTakeInfo_Value(take, "I_CHANMODE")
if chanmode == 0 then
r.SetMediaItemTakeInfo_Value(take, "I_CHANMODE", 3)
chanmode = 3
end

local src = r.GetMediaItemTake_Source(take)
if chanmode >= 3 then
return r.GetMediaSourceFileName(src, ""), math.floor(chanmode - 2)
else
return r.GetMediaSourceFileName(src, ""), nil
end
end

function CountDisarmedBefore(channelIndex, src)
local disarmedCount = 0
for i = 1, channelIndex - 1 do
local tag = (i == 1)
and "IXML:AATON_CANTAR:ALL_TRK_NAME:DATA:ACTIVE"
or ("IXML:AATON_CANTAR:ALL_TRK_NAME:DATA:ACTIVE:" .. i)
local _, value = r.GetMediaFileMetadata(src, tag)
if value == "DISARMED" then
disarmedCount = disarmedCount + 1
end
end
return disarmedCount
end

function RenameItem(item, option)
local path, chanIndex = GetItemSourcePath(item)
if not path or not chanIndex then return end

local src = r.PCM_Source_CreateFromFile(path)
if not src then
Msg("Unable to load file: " .. path)
return
end

local _, sceneValue = r.GetMediaFileMetadata(src, "IXML:SCENE")
local _, takeValue = r.GetMediaFileMetadata(src, "IXML:TAKE")

local tag = "dTRK" .. chanIndex
local _, name = r.GetMediaFileMetadata(src, tag)

if not name or name == "" then
local disarmTag = chanIndex == 1
and "IXML:AATON_CANTAR:ALL_TRK_NAME:DATA:ACTIVE"
or ("IXML:AATON_CANTAR:ALL_TRK_NAME:DATA:ACTIVE:" .. chanIndex)
local _, isDisarmed = r.GetMediaFileMetadata(src, disarmTag)

if isDisarmed == "DISARMED" then
name = "DISARMED"
else
local disarmedBefore = CountDisarmedBefore(chanIndex, src)
local adjustedIndex = chanIndex - disarmedBefore
local ixmlTag = adjustedIndex == 1
and "IXML:TRACK_LIST:TRACK:NAME"
or ("IXML:TRACK_LIST:TRACK:NAME:" .. adjustedIndex)
local _, ixmlName = r.GetMediaFileMetadata(src, ixmlTag)
name = (ixmlName and ixmlName ~= "") and ixmlName or "[Name not found]"
end
end

if option == 1 and sceneValue and takeValue then
name = sceneValue .. "/" .. takeValue .. " - " .. name
end

r.GetSetMediaItemTakeInfo_String(r.GetActiveTake(item), "P_NAME", name, true)
r.PCM_Source_Destroy(src)
end

-- ImGui UI
local function loop()
local visible, open = r.ImGui_Begin(ctx, 'Rename Items', true)
if visible then
r.ImGui_PushFont(ctx, FONT)
r.ImGui_Text(ctx, 'Choose renaming mode:')

if r.ImGui_RadioButton(ctx, '1: SCENE/TAKE - Track name', option == 1) then option = 1 end
if r.ImGui_RadioButton(ctx, '2: Track name only', option == 2) then option = 2 end

if r.ImGui_Button(ctx, 'Rename selected items') then
r.Undo_BeginBlock()
local itemCount = r.CountSelectedMediaItems(0)
if itemCount == 0 then
Msg("No items selected.")
else
for i = 0, itemCount - 1 do
local item = r.GetSelectedMediaItem(0, i)
RenameItem(item, option)
end
end
r.Undo_EndBlock("Rename items based on metadata", -1)
end

r.ImGui_PopFont(ctx)
r.ImGui_End(ctx)
end

if open then
r.defer(loop)
else
if r.ImGui_DestroyContext then
r.ImGui_DestroyContext(ctx)
end
end
end

r.defer(loop)
