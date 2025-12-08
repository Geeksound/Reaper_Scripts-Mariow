--[[
@description Insert a new track and adjust it (Pro Tools style)
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-11-26)
  - Initial release
@provides
  [main] Protools_Track/InsertNewTrack(PT).lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags track, insert, rename, height, editing
@about
  # Insert New Track (Pro Tools style)
  Inserts a new track in REAPER, sets its height (Xenakios/SWS), 
  and opens the rename dialog for the new track.
--]]

-- Insert new track
reaper.Main_OnCommand(40001, 0)

-- Xenakios/SWS: Set selected tracks heights to B
reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_SELTRAXHEIGHTB"), 0)

-- Xenakios/SWS: Rename selected tracks...
reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_RENAMETRAXDLG"), 0)

