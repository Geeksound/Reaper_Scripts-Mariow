--[[
@description Select Empty Items from DISARMED Cantar Files on Shooting
@author Mariow
@license MIT
@changelog
  v1.0 (2025-11-05)
  - Select all mono items marked as DISARMED in Cantar iXML metadata
@provides
  [main] Field-Recorder_Workflow/Select_DISARMED_Items.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags dialogue conformation workflow fieldrecording cantar disarmed
@about
  # Select_DISARMED_Items

  This script scans all items in the session.
  It selects those whose metadata tag "IXML:AATON_CANTAR:ALL_TRK_NAME:DATA:ACTIVE:n"
  indicates "DISARMED" for their respective mono channel.
--]]

local r = reaper

function Msg(str)
  r.ShowConsoleMsg(tostring(str) .. "\n")
end

-- Get item source path + channel index
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
    return nil, nil
  end
end

-- Check if the item is DISARMED
function IsDisarmed(item)
  local path, chanIndex = GetItemSourcePath(item)
  if not path or not chanIndex then return false end

  local src = r.PCM_Source_CreateFromFile(path)
  if not src then return false end

  local tag = (chanIndex == 1)
    and "IXML:AATON_CANTAR:ALL_TRK_NAME:DATA:ACTIVE"
    or ("IXML:AATON_CANTAR:ALL_TRK_NAME:DATA:ACTIVE:" .. chanIndex)

  local _, value = r.GetMediaFileMetadata(src, tag)
  r.PCM_Source_Destroy(src)

  return (value == "DISARMED")
end

-- Main
r.Undo_BeginBlock()
r.Main_OnCommand(40289, 0) -- Unselect all items

local itemCount = r.CountMediaItems(0)
local disarmedCount = 0

for i = 0, itemCount - 1 do
  local item = r.GetMediaItem(0, i)
  if IsDisarmed(item) then
    r.SetMediaItemSelected(item, true)
    disarmedCount = disarmedCount + 1
  end
end

r.UpdateArrange()
r.Undo_EndBlock("Select DISARMED items", -1)

Msg("Here is the Mono Files corresponding to Tracks\nin CANTAR that were DISARMED during shooting.\n"..
disarmedCount .. " Files found\nYou can delete them")
