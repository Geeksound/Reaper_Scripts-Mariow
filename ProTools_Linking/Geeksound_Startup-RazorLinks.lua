--[[
@description Startup - Ensure Razor Edit Track + TimeSelection + Loop linked
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-03-15)
  - Initial release
@provides
  [main] ProTools_Linking/Geeksound_Startup-RazorLinks.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags startup, razor edit, timesel, loop, linking, (protools-like)
@about
  Ensures at REAPER startup:
  1. Razor Edit → Track Selection active
  2. Razor Edit ↔ Time Selection active
  3. Loop points linked to Time Selection (safe)
  This script is intended for REAPER Startup Actions.
--]]

--------------------------------------------------
-- Command IDs of the scripts
--------------------------------------------------
--Geeksound_ToggleLink-RazorToTimeSelection(PT like).lua
local SCRIPT1_CMD = reaper.NamedCommandLookup("_RSe567e326b9bbbe9346e7ff84479bacdd43a3b68f") -- Timesel Follow
--Geeksound_ToggleLink-RazorToTracks(PT like).lua
local SCRIPT2_CMD = reaper.NamedCommandLookup("_RS10a1772219744d2780f0683c4757f7441436d3a4") -- Track Follow

--------------------------------------------------
-- Ensure Script1 is running
--------------------------------------------------
if SCRIPT1_CMD ~= 0 and reaper.GetToggleCommandState(SCRIPT1_CMD) ~= 1 then
    reaper.Main_OnCommand(SCRIPT1_CMD, 0)
end

--------------------------------------------------
-- Ensure Script2 is running
--------------------------------------------------
if SCRIPT2_CMD ~= 0 and reaper.GetToggleCommandState(SCRIPT2_CMD) ~= 1 then
    reaper.Main_OnCommand(SCRIPT2_CMD, 0)
end

--------------------------------------------------
-- Ensure Loop Points linked to Time Selection
--------------------------------------------------
-- CommandID 40621 = "Options: Toggle loop points linked to time selection"
local LOOPLINK_CMD = 40621

if reaper.GetToggleCommandState(LOOPLINK_CMD) ~= 1 then
    -- si toggle OFF → activer
    reaper.Main_OnCommand(LOOPLINK_CMD, 0)
end
