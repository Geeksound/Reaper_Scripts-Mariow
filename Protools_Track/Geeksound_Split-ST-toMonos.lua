--[[
@description Split Stereo to Monos (ProTools-like)
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-06-07)
  - Initial release
@provides
  [main] Protools_Track/Split-ST-toMonos.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags editing, items, audio, explode, channels, prottools-like
@about
  # Split Stereo to Monos (ProTools-like)
  Mimics Pro Tools' workflow for breaking a stereo clip into two mono clips.
  The script:
  - Inserts a temporary track
  - Moves/duplicates the item
  - Explodes the stereo item into 2 mono items using REAPER's native function
  - Restores folder states via SWS
  - Cleans up temporary tracks
--]]

-- Insert new track
reaper.Main_OnCommand(40001, 0)

-- Go to previous track
reaper.Main_OnCommand(40286, 0)

-- Select all items in track
reaper.Main_OnCommand(40421, 0)

-- Explode multichannel audio or MIDI to new one-channel items
reaper.Main_OnCommand(40894, 0)

-- SWS/S&M: Set selected tracks folder states to normal
reaper.Main_OnCommand(reaper.NamedCommandLookup("_S&M_FOLDEROFF"), 0)

-- Remove tracks
reaper.Main_OnCommand(40005, 0)

