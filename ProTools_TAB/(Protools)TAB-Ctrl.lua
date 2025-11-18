--[[
@description ProTools TAB - Ctrl+TAB (Select Next Item)
@version 1.0
@author Mariow
@changelog
	v1.0 (2025-11-17)
	- Initial release
@provides
	[main] ProTools_TAB/(ProTools)TAB-Ctrl.lua
@tags protools, tab, item, selection, editing, next
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@about
	# ProTools TAB - Ctrl+TAB (Select Next Item)
	
	This script emulates the **Ctrl+TAB behavior** from ProTools in REAPER:
	- Select next Item in selected Track

	
	## Features:
	- Mimics ProTools’ Ctrl+TAB behavior for precise, keyboard-driven item selection.
	- Undo-friendly with a descriptive undo block.
	- Ideal for fast navigation and selection between consecutive items.
--]]

reaper.Undo_BeginBlock()

reaper.Main_OnCommand(40417, 0)  -- Select and move to next item

reaper.Undo_EndBlock("Select next item (Ctrl+Tab style)", -1)

