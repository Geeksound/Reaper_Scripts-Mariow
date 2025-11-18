--[[
@description ProTools TAB - Toggle TabToTransient (Keyboard Shortcut)
@version 1.1
@author Mariow
@changelog
    V1.1 (2025-06-07)
    - RS Number Upadate in code
    v1.0 (2025-06-07)
    - Initial release
@provides
    [main] ProTools_TAB/(Protools)TAB-TransientToggleShortcut.lua
@tags protools, transient, tab, shortcut, editing
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@about
    # ProTools TAB - TabToTransient Toggle (Shortcut)
    
    Keyboard–shortcut version of the TabToTransient button.
    
    ## Rules:
    - Activates TabToTransient and disables Fade (as in Pro Tools)
    - If TabToTransient is already enabled:
        - it is turned OFF
        - Fade is turned back ON
    - Updates:
        - the Transient toolbar button
        - the Fade toolbar button
        - the ImGui interface
        - the shared ExtState
        
    This script ensures consistent system behavior even without mouse interaction.
--]]

local namespace = "ProTools_TAB"

-- Lire état actuel
local current = reaper.GetExtState(namespace, "TabToTransient") == "1"

if current then
    reaper.SetExtState(namespace, "TabToTransient", "0", true)
    reaper.SetExtState(namespace, "Fade", "1", true)
else
    reaper.SetExtState(namespace, "TabToTransient", "1", true)
    reaper.SetExtState(namespace, "Fade", "0", true)
end

-- 🔵 MISE À JOUR DES BOUTONS TOOLBAR
do
    local fade_commandID = reaper.NamedCommandLookup("_RS9660f424e64c0735a524774e52e173a6e638bdfa")  -- "RS1"
    local transient_commandID = reaper.NamedCommandLookup("_RSb0daa3cdff54c89e91d18544ce23fca5f3290582") -- "RS2"
    local sectionID = 0 -- main section

    local fade_enabled = reaper.GetExtState(namespace, "Fade") == "1"
    local tab_to_transient = reaper.GetExtState(namespace, "TabToTransient") == "1"

    if fade_commandID then
        reaper.SetToggleCommandState(sectionID, fade_commandID, fade_enabled and 1 or 0)
        reaper.RefreshToolbar2(sectionID, fade_commandID)
    end

    if transient_commandID then
        reaper.SetToggleCommandState(sectionID, transient_commandID, tab_to_transient and 1 or 0)
        reaper.RefreshToolbar2(sectionID, transient_commandID)
    end
end

