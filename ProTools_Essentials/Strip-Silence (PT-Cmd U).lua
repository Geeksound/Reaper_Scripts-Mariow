--[[
@description Strip Silence (ProTools-like)
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-06-07)
  - Initial release: executes REAPER's Strip Silence action
@provides
  [main] ProTools_Essentials/Strip-Silence (PT-Cmd U).lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags editing, items, silence, cleanup, (protools-like)
@about
  # Strip Silence (ProTools-like)
  Executes the native REAPER Strip Silence command,
  mimicking Pro Tools’ Cmd+U workflow.
--]]

reaper.Main_OnCommand(40315, 0)

