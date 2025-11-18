--[[
@description ProTools TAB - Toggle Fade (Toolbar Button RS1)
@version 1.0
@author Mariow
@changelog
	v1.0 (2025-06-07)
	- Initial release
@provides
	[main] ProTools_TAB/(Protools)TAB-FadeToggleToolbarID.lua
@tags protools, fade, editing, toolbar
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@about
	# ProTools TAB - Fade Toggle (Toolbar)
	
	This script provides a **toolbar button** used to enable or disable the Fade mode  
	without needing to open the ImGui window.
	
	## Functions:
	- Reads the current Fade state from ExtState
	- Toggles the state
	- Updates its own toolbar toggle button (ON/OFF)
	- Notifies the main ImGui script through ExtState
	
	This button stays fully synchronized with:
	- the ImGui interface
	- the Transient button
	- the associated keyboard shortcuts
--]]

local section = 0 -- Main section

-- Lire l'état actuel
local fade_enabled = reaper.GetExtState("ProTools_TAB", "Fade") == "1"

-- Inverser l'état
fade_enabled = not fade_enabled

-- Sauvegarder l'état
reaper.SetExtState("ProTools_TAB", "Fade", fade_enabled and "1" or "0", true)

-- Mettre à jour l'état de toggle dans la toolbar
local _, _, sectionID, commandID = reaper.get_action_context()
reaper.SetToggleCommandState(sectionID, commandID, fade_enabled and 1 or 0)
reaper.RefreshToolbar2(sectionID, commandID)

