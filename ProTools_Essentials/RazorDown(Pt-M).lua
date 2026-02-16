--[[
@description Move Razor Areas Down (Pt-Like M)
@version 1.0
@author Mariow
@changelog
    v1.0 (2026-02-16)
    - Initial release
    - If Razor Areas exist: moves them down
    - If no Razor Areas but media items are selected: encloses items first, then moves down
@provides
    [main] ProTools_Essentials/RazorDown(Pt-M).lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags editing, razor, smart, move, items, (protools-like)
@about
    # Smart Razor: Move Areas Down (ProTools-like)

    This script enhances REAPER’s native:
    **"Razor edit: Move areas down without contents"**

    ## 🟦 Behavior

    - If Razor Areas already exist → moves them down.
    - If no Razor Areas exist but media items are selected →
      automatically runs **"Razor edit: Enclose media items"**
      before moving the areas down.
    - If nothing is selected → no action.

    ## 🟩 Purpose

    Provides a smoother editing workflow by eliminating the need
    to manually create Razor Areas before moving them.

    Designed for fast keyboard-driven editing.

    ## 🔗 Part of the ProTools_Essentials Suite

    Works seamlessly alongside the other Smart Razor tools
    and TimecodeUI-based editing scripts.
--]]


reaper.Undo_BeginBlock()

local function RazorAreaExists()
    local trackCount = reaper.CountTracks(0)
    for i = 0, trackCount - 1 do
        local track = reaper.GetTrack(0, i)
        local retval, razor = reaper.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", "", false)
        if razor ~= "" then
            return true
        end
    end
    return false
end

local razorExists = RazorAreaExists()
local selectedItemCount = reaper.CountSelectedMediaItems(0)

if razorExists then
    -- Move Razor Areas down
    reaper.Main_OnCommand(42403, 0)

elseif selectedItemCount > 0 then
    -- Enclose selected items in Razor Area
    reaper.Main_OnCommand(42630, 0)
    -- Then move down
    reaper.Main_OnCommand(42403, 0)
end

reaper.Undo_EndBlock("Smart Razor: Move Down", -1)

