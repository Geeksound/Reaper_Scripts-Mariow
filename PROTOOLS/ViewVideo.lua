--[[
@description Show video window only if hidden
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-12-17)
  - Initial release
  - Checks the ON/OFF state of the video window
  - Shows the video window only if it is currently hidden
@provides
  [main] PROTOOLS/ViewVideo.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags video, window, toggle, workflow, utility
@about
  # Show Video Window If Hidden
  
  A simple utility script for REAPER that checks the current visibility
  state of the video window.
  
  Behavior:
  - If the video window is already visible, nothing happens.
  - If the video window is hidden, the script shows it automatically.
  
  This script is useful for ensuring the video window is available
  without accidentally toggling it off.
--]]

-- Command ID : Video: Show/hide video window
local cmdID = 50125

-- Vérifie l'état ON/OFF de la commande
local state = reaper.GetToggleCommandState(cmdID)

-- Si OFF (0), on affiche la fenêtre vidéo
if state == 0 then
    reaper.Main_OnCommand(cmdID, 0)
end

