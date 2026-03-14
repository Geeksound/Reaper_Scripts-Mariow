--[[
@description ProTools TAB - Toggle TabToTransient & Disable Fade (Toolbar Button)
@version 1.2
@author Mariow
@changelog
    v1.2 (2026-03-14)
  - Geeksound Command ID 
    V1.1 (2025-06-07)
    - RS Number Upadate in code
    v1.0 (2025-06-07)
    - Initial release
@provides
    [main] ProTools_TAB/Geeksound_(Protools)TAB-TransientToggleToolbarID.lua
@tags protools, transient, tab, editing, toolbar
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@about
    # ProTools TAB - Toggle Transient (Toolbar)
    
    Toolbar button used to enable or disable the **TabToTransient** mode,
    replicating the behavior found in Pro Tools.
    
    ## Logic rules:
    - If TabToTransient is ON → Fade is forced OFF  
    - If TabToTransient is OFF → the mode is simply disabled
    - Updates its own toolbar toggle state
    - Forces the Fade toolbar button to OFF when required
    
    This button stays fully synchronized with:
    - the ImGui interface
    - the equivalent keyboard shortcuts
    - the shared ExtState
--]]

local namespace = "ProTools_TAB"

-- Lire l'état actuel de TabToTransient
local tab_to_transient = reaper.GetExtState(namespace, "TabToTransient") == "1"

-- Toggle TabToTransient
tab_to_transient = not tab_to_transient
reaper.SetExtState(namespace, "TabToTransient", tab_to_transient and "1" or "0", true)

-- Si on active TabToTransient → désactiver Fade
if tab_to_transient then
    reaper.SetExtState(namespace, "Fade", "0", true)
end

-- Mettre à jour le bouton Fade dans la toolbar
do
    -- On récupère le contexte du script Fade
    local fade_commandID = reaper.NamedCommandLookup("_RS9e4cf7c1db6dfbada996402eed2f9a144458ecda") -- "RS1"
    local fade_sectionID = 0 -- Main section
    if fade_commandID then
        reaper.SetToggleCommandState(fade_sectionID, fade_commandID, 0) -- OFF
        reaper.RefreshToolbar2(fade_sectionID, fade_commandID)
    end
end

-- Mettre à jour le bouton actuel (Transient) dans la toolbar
local _, _, sectionID, commandID = reaper.get_action_context()
reaper.SetToggleCommandState(sectionID, commandID, tab_to_transient and 1 or 0)
reaper.RefreshToolbar2(sectionID, commandID)

