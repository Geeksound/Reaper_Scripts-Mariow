--[[
@description ProTools TAB - Toggle Fade (Keyboard Shortcut)
@version 1.0
@author Mariow
@changelog
    v1.0 (2025-06-07)
    - Initial release
@provides
    [main] ProTools_TAB/(Protools)TAB-FadeToggleShortcut.lua
@tags protools, fade, shortcut, editing
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@about
    # ProTools TAB - Fade Toggle (Shortcut)
    
    Keyboard–shortcut version of the Fade button.
    
    ## Features:
    - Enables or disables Fade
    - Always deactivates TabToTransient (as in Pro Tools)
    - Updates:
        - the Fade & Transient toolbar buttons
        - the ImGui interface
        - the shared ExtState
        
    This script allows a fully keyboard-driven workflow without losing synchronization.
--]]


local namespace = "ProTools_TAB"

-- Lire état actuel
local fade_enabled = reaper.GetExtState(namespace, "Fade") == "1"

if fade_enabled then
    -----------------------------------------
    -- 🟥 Fade était ON → on désactive
    -----------------------------------------
    reaper.SetExtState(namespace, "Fade", "0", true)
    -- TabToTransient doit être OFF quand Fade OFF (selon ta logique)
    reaper.SetExtState(namespace, "TabToTransient", "0", true)
else
    -----------------------------------------
    -- 🟩 Fade était OFF → on active
    -----------------------------------------
    reaper.SetExtState(namespace, "Fade", "1", true)
    -- TabToTransient doit être OFF quand Fade ON
    reaper.SetExtState(namespace, "TabToTransient", "0", true)
end

-- 🔵 MISE À JOUR DES BOUTONS TOOLBAR
do
    local fade_commandID = reaper.NamedCommandLookup("_RS2d59b548b081423aba5dd398d28248e0299189a2") -- "RS1"
    local transient_commandID = reaper.NamedCommandLookup("_RS36d30cfe1671aaa3a7c08bfebbce56c43dae2c20") -- "RS2"
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

