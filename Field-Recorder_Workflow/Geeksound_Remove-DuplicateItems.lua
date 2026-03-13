--[[
@description Remove-DuplicateItems
@version 1.0
@author Mariow
@license MIT
@changelog
  v1.0 (2025-06-08)
  - Initial release
@provides
  [main] Field-Recorder_Workflow/Remove-DuplicateItems.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags dialogue conformation workflow Fieldrecording Track
@about
  # Remove-DuplicateItems

  This script comes after Auto-matching Conformation.
  - After automatching conformation, unnecessary duplicate items may be imported in the session.
  - This script deletes duplicate items (same name + same length) on selected tracks, and keeps the one on the highest track.

  This script was developed with the help of GitHub Copilot.
--]]



reaper.Undo_BeginBlock()

-- Message for user
local retval = reaper.ShowMessageBox("Remove Unnecessary Duplicates Items after AutoMatching Conformation", "Feature", 1)
if retval ~= 1 then
  return -- Annuler le script
end

local selected_tracks = {}
local track_index_map = {}

-- select all tracks
reaper.Main_OnCommand(40296, 0) -- Item: Split at edit cursor

-- Collect Tracks
local sel_track_count = reaper.CountSelectedTracks(0)
for i = 0, sel_track_count - 1 do
  local track = reaper.GetSelectedTrack(0, i)
  selected_tracks[#selected_tracks + 1] = track
  local idx = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
  track_index_map[track] = idx
end

-- Check selected
local function is_track_selected(track)
  return track_index_map[track] ~= nil
end

-- Sort by Regrouper les items par (name + lenght)
local item_map = {}

for i = 0, reaper.CountMediaItems(0) - 1 do
  local item = reaper.GetMediaItem(0, i)
  local track = reaper.GetMediaItemTrack(item)
  if is_track_selected(track) then
    local take = reaper.GetActiveTake(item)
    if take and not reaper.TakeIsMIDI(take) then
      local _, name = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)
      local length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
      if name and name ~= "" then
        local key = name .. "_" .. string.format("%.8f", length)
        if not item_map[key] then
          item_map[key] = {}
        end
        table.insert(item_map[key], { item = item, track = track, track_idx = track_index_map[track] })
      end
    end
  end
end

-- Searching duplicates
local items_to_delete = {}

for _, group in pairs(item_map) do
  if #group > 1 then
    -- Trier les items par numéro de piste croissant
    table.sort(group, function(a, b) return a.track_idx < b.track_idx end)
    -- Garder celui sur la piste la plus haute, supprimer les autres
    for i = 2, #group do
      table.insert(items_to_delete, group[i].item)
    end
  end
end

-- Del selected
for _, item in ipairs(items_to_delete) do
  local track = reaper.GetMediaItemTrack(item)
  reaper.DeleteTrackMediaItem(track, item)
end

-- Unselect ALL
reaper.Main_OnCommand(40297, 0)

reaper.UpdateArrange()
reaper.Undo_EndBlock("Remove duplicates (name+length) in the project", -1)

