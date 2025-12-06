--[[
@description Double the length of the Time Selection
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-11-26)
  - Initial release
@provides
  [main] 

@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags time selection, editing, items
@about
  # Double Time Selection Length
  Doubles the length of the current Time Selection in REAPER.
  Moves loop points to the selection, doubles the loop, then restores the time selection.
--]]

-- Vérifier si une Time Selection existe
local start_time, end_time = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)
if end_time <= start_time then
    reaper.ShowMessageBox("Please Make a Timeselection !", "DoubleTimeLength", 0)
    return
end

reaper.Main_OnCommand(42406,0)
-- Move loop points to time selection
reaper.Main_OnCommand(40622, 0)

-- Double loop length
reaper.Main_OnCommand(40722, 0)

-- Move time selection to loop points
reaper.Main_OnCommand(40623, 0)

