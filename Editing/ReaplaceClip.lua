--[[
@description ReaPlaceClip - Replace Clip like in Pro Tools
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-11-04)
  - Initial release
  - Replaces all occurrences of a selected source clip with a new audio file
  - Automatically rebuilds peaks (cmd 40441) for updated waveforms

@provides
  [main] Editing/ReaPlaceClip.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags audio, editing, replace, clip, protols, source
@about
  # ReaPlaceClip
  A Pro Tools–style “Replace Clip” workflow for Reaper.
  
  This script allows you to select an item (clip) in your session, 
  choose a new audio file, and automatically replace **all occurrences** 
  of that clip’s source file throughout the project.

  Perfect for post-production, sound design, or ADR workflows where 
  you need to globally update a sound (e.g., replacing "Door_Open1.wav" 
  with "Door_Open2.wav").

  Inspired by the *Replace Clip* feature in Avid Pro Tools.
--]]

reaper.Undo_BeginBlock()

-- Get the selected item (clip to replace)
local item = reaper.GetSelectedMediaItem(0, 0)
if not item then
  reaper.ShowMessageBox("Please select an item to replace first.", "Replace Clip", 0)
  return
end

-- Get the active take and its source file
local take = reaper.GetActiveTake(item)
if not take then return end
local src = reaper.GetMediaItemTake_Source(take)
local old_path = reaper.GetMediaSourceFileName(src, "")

-- Ask the user to choose the new audio file
retval, new_path = reaper.GetUserFileNameForRead("", "Select the new audio file", "wav")

if retval == false or new_path == "" then return end

local replaced_count = 0

-- Loop through all items in the project
local item_count = reaper.CountMediaItems(0)
for i = 0, item_count - 1 do
  local it = reaper.GetMediaItem(0, i)
  local tk = reaper.GetActiveTake(it)
  if tk then
    local sc = reaper.GetMediaItemTake_Source(tk)
    local src_path = reaper.GetMediaSourceFileName(sc, "")
    -- If the source file matches the one to be replaced:
    if src_path == old_path then
      local new_src = reaper.PCM_Source_CreateFromFile(new_path)
      reaper.SetMediaItemTake_Source(tk, new_src)
      replaced_count = replaced_count + 1
    end
  end
end

-- Rebuild waveforms (cmd ID 40441)
reaper.Main_OnCommand(40441, 0)

reaper.Undo_EndBlock("Replace source file in session", -1)
reaper.UpdateArrange()

-- Uncomment the line below if you want a confirmation dialog after replacement
-- reaper.ShowMessageBox("Replacement complete: " .. replaced_count .. " clip(s) replaced.", "Replace Clip", 0)

