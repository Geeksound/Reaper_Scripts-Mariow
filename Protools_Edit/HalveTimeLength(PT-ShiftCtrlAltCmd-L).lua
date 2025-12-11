--[[
@description Halve the length of the Time Selection
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-11-26)
  - Initial release
@provides
  [main] Protools_Edit/HalveTimeLength(PT-ShiftCtrlAltCmd-L).lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags time selection, editing, items
@about
  # Halve Time Selection Length
  Halves the length of the current Time Selection in REAPER.
  Works by moving the loop points, halving the loop length, and restoring the time selection.
--]]

-- Vérifier si une Time Selection existe
local start_time, end_time = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)
if end_time <= start_time then
    reaper.ShowMessageBox("Please Make a Timeselection !", "HalveTimeLength", 0)
    return
end

reaper.Main_OnCommand(42406,0)
-- Move loop points to time selection
reaper.Main_OnCommand(40622, 0)

-- Halve loop length
reaper.Main_OnCommand(40721, 0)

-- Move time selection to loop points
reaper.Main_OnCommand(40623, 0)

