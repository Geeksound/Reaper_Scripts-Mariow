--[[
@description MoveItemUP/Down-OneKNOB
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-11-10)
  - ImGui interface version with dynamic button
@provides
  [main] Utility/MoveItem-OneKNOB.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags items, tracks, editing, gui, imgui
@about
  # Move selected item Up/Down (ImGui interface)
  Displays a small window with a button to move the selected item.
  Default = move down, hold Alt (Option) = move up.
  Automatically creates a new track if needed.
--]]

local r = reaper
local ctx = r.ImGui_CreateContext('Move Item Up/Down')

----------------------------------------
-- Helpers
----------------------------------------

local function TrackNameExists(name)
  for i = 0, r.CountTracks(0) - 1 do
    local tr = r.GetTrack(0, i)
    local _, trName = r.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
    if trName == name then return true end
  end
  return false
end

local function GetUniqueTrackName(baseName)
  local newName = baseName
  local count = 2
  while TrackNameExists(newName) do
    newName = string.format("%s (%d)", baseName, count)
    count = count + 1
  end
  return newName
end

local function MoveItem(direction)
  local item = r.GetSelectedMediaItem(0, 0)
  if not item then
    r.ShowMessageBox("No item selected.", "Error", 0)
    return
  end

  local track = r.GetMediaItem_Track(item)
  local trackIndex = r.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER") - 1
  local targetTrack

  if direction == "up" then
    if trackIndex == 0 then
      r.ShowMessageBox("Cannot move up: already on the first track.", "Info", 0)
      return
    end
    targetTrack = r.GetTrack(0, trackIndex - 1)
  else
    targetTrack = r.GetTrack(0, trackIndex + 1)
    if not targetTrack then
      r.InsertTrackAtIndex(trackIndex + 1, true)
      r.TrackList_AdjustWindows(false)
      targetTrack = r.GetTrack(0, trackIndex + 1)
      local take = r.GetActiveTake(item)
      local takeName = take and r.GetTakeName(take) or "New Track"
      local uniqueName = GetUniqueTrackName(takeName)
      r.GetSetMediaTrackInfo_String(targetTrack, "P_NAME", uniqueName, true)
    end
  end

  r.MoveMediaItemToTrack(item, targetTrack)
  r.UpdateArrange()
end

----------------------------------------
-- GUI Loop
----------------------------------------

function loop()
  r.ImGui_SetNextWindowSize(ctx, 200, 90, r.ImGui_Cond_FirstUseEver())
  local visible, open = r.ImGui_Begin(ctx, 'Item UP/DWN (by Mariow)', true)

  if visible then
    local mods = r.ImGui_GetKeyMods(ctx)
    local isAlt = (mods & r.ImGui_Mod_Alt()) ~= 0
    local label = isAlt and "Move Up ⬆️" or "Move Down ⬇️"
    local color = isAlt and 0xFFAA66FF or 0x66CCFFFF

    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(), color)
    if r.ImGui_Button(ctx, label, 150, 35) then
      MoveItem(isAlt and "up" or "down")
    end
    r.ImGui_PopStyleColor(ctx)

    r.ImGui_Text(ctx, "Hold Alt (Option) to move up")
    r.ImGui_End(ctx)
  end

  if open then
    r.defer(loop)
  else
    -- Older ReaImGui versions don't have DestroyContext
    if r.ImGui_DestroyContext then
      r.ImGui_DestroyContext(ctx)
    end
  end

end

loop()

