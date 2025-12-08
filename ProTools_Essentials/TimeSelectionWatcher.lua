--[[
@description Watcher: stores last valid Time Selection for RestoreLastSelection (ProTools-like)
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-06-07)
  - Initial release
@provides
  [main] ProTools_Essentials/TimeSelectionWatcher.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags editing, timesel, watcher, (protools-like)
@about
  # TimeSelectionWatcher (ProTools-like)
  Continuously monitors the project’s Time Selection and stores
  the last valid (non-empty) selection in ExtState for use with
  RestoreLastSelection.lua.
  Shoulb be placed in Startup Action
--]]

local last_start = -1
local last_end   = -1

local function Watch()
    local ts_start, ts_end = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)

    -- Only store non-empty TS
    if ts_start ~= ts_end then
        if ts_start ~= last_start or ts_end ~= last_end then
            last_start = ts_start
            last_end = ts_end
            reaper.SetExtState("PT_TS","last_start",tostring(ts_start),true) -- persistent
            reaper.SetExtState("PT_TS","last_end",tostring(ts_end),true)
        end
    end

    reaper.defer(Watch)
end

Watch()

