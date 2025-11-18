--[[
@description ProTools TAB - (Ctrl/Alt)+TAB (Select Previous Item)
@version 1.0
@author Mariow
@changelog
	v1.0 (2025-11-17)
	- Initial release
@provides
	[main] ProTools_TAB/(ProTools)TAB-Ctrl(Alt).lua
@tags protools, tab, item, selection, editing, previous
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@about
	# ProTools TAB -(Ctrl/Alt)+ TAB (Select Previous Item)
	
	This script emulates the **(Ctrl/Alt)+TAB behavior** from ProTools in REAPER:
	
	- Moves the edit cursor to the start of the previous media item on the selected track(s).
	- Selects that item, extending selection strictly **item by item in reverse order**.
	- Works seamlessly with the ProTools TAB workflow and shared ExtState.
	
	## Features:
	- Select previous Item in selected track;
--]]

reaper.Undo_BeginBlock()

reaper.Main_OnCommand(40416, 0)  -- Select and move to next item

reaper.Undo_EndBlock("Select next item (Ctrl+Tab style)", -1)
