--[[
@description Group selected tracks (ProTools-like)
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-11-25)
  - Initial release: executes the "Group tracks" command (ID 40772)
@provides
  [main] Protools_Track/GroupTracks(PT-CmdG).lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags editing, tracks, grouping, (protools-like)
@about
  # GroupTracks (ProTools-like)
  Executes the REAPER command to group selected tracks, emulating Pro Tools' Cmd+G behavior.
--]]

reaper.Main_OnCommand(40772, 0)

