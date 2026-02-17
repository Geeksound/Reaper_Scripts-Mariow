--[[
@description RatingClip –Reset (PT-Like)
@version 1.0
@author Mariow
@changelog
    v1.0 (2026-02-16)
    - Initial release
    - Clears clip rating
@provides
    [main] ProTools_Essentials/RatingClip-Reset.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags rating, clip, protools-like, editing
@about
    # RatingClip – Reset (PT-Like)

    Clears rating of selected clips
    using REAPER’s native clear rank action.

    Part of the ProTools_Essentials suite.
--]]

reaper.Undo_BeginBlock()
reaper.Main_OnCommand(43161, 0)
reaper.Undo_EndBlock("Reset Rating", -1)

