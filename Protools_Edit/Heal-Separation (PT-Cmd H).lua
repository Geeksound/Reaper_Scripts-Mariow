--[[
@description Heal Separatin (ProTools-like)
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-11-25)
  - Initial release: executes the sequence of commands to "Heal" items in the current time selection
@provides
  [main] Protools_Edit/Heal-Separation.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags editing, items, timesel, (protools-like)
@about
  # Heal-Separation (ProTools-like)
  Executes a series of REAPER commands to perform the "Heal" operation
  within the current Time Selection, emulating Pro Tools' Cmd+H behavior.
--]]


reaper.Main_OnCommand(40718, 0)
reaper.Main_OnCommand(40548, 0)
reaper.Main_OnCommand(40289, 0)
reaper.Main_OnCommand(40635, 0)

