--[[
@description RestorelastTime Selection(ProTools-like)
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-06-07)
  - Initial release
@provides
  [main] ProTools_Essentials/RestoreLastSelection.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags editing, items, timesel, watcher-dependency, (protools-like)
@about
  # RestoreLastSelection (ProTools-like)
  Restores the last stored Time Selection in the project, emulating Pro Tools’ behavior.
  This script requires TimeSelectionWatcher.lua to be running (e.g., in Startup Actions)
  to track and store the last valid Time Selection.
--]]



local start = tonumber(reaper.GetExtState("PT_TS","last_start") or "")
local stop  = tonumber(reaper.GetExtState("PT_TS","last_end") or "")

if start and stop and start ~= stop then
    reaper.GetSet_LoopTimeRange(true,false,start,stop,false)
else
    reaper.ShowMessageBox("No previous Time Selection stored.","Restore Last TS",0)
end

