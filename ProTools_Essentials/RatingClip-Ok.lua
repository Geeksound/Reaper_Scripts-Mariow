--[[
@description RatingClip – Ok (PT-Like)
@version 1.0
@author Mariow
@changelog
    v1.0 (2026-02-16)
    - Initial release
    - Sets clip rating to Ok
@provides
    [main] ProTools_Essentials/RatingClip-Ok.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags rating, clip, protools-like, editing
@about
    # RatingClip – Ok (PT-Like)

    Sets selected clips to **Ok** rating
    using REAPER’s native up-rank system.

    Part of the ProTools_Essentials suite.
--]]


reaper.Undo_BeginBlock()

local CLEAR = 43161
local CYCLE = 43197
local TARGET = 1

local item_count = reaper.CountSelectedMediaItems(0)

for i = 0, item_count - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    reaper.SetMediaItemSelected(item, true)

    reaper.Main_OnCommand(CLEAR, 0)

    for j = 1, TARGET do
        reaper.Main_OnCommand(CYCLE, 0)
    end
end

reaper.Undo_EndBlock("Set Rating 1", -1)

