--[[
@description Copy items (ProTools ⌘C style)
@version 1.0
@author Mariow
@changelog
	v1.0 (2025-12-06)
	- Initial release: simulate Pro Tools ⌘C, copy items under mouse or selected items, clear time selection
@provides
	[main] Protools_Edit/Copy_Items.lua
@tags editing, copy, takes, (protools-like)
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@about
	# Copy Items (ProTools-like)
	Simulates Pro Tools **⌘C** workflow:
	- Copy the item under the mouse or the selected items  
	- Clear time selection
--]]


-- 1. Activer l’action mousewheel / volume action (ou juste préparation de sélection)
reaper.Main_OnCommand(40528, 0)

-- 2. Copy items
reaper.Main_OnCommand(40060, 0)

-- 3. Remove Time Selection
reaper.Main_OnCommand(40289, 0)

