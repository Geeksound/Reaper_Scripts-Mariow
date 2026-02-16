--[[
@description Move Razor Areas Up (Pt-Like P)
@version 1.0
@author Mariow
@changelog
    v1.0 (2026-02-16)
    - Initial release
    - If Razor Areas exist: moves them up
    - If no Razor Areas but media items are selected: encloses items first, then moves up
@provides
    [main] ProTools_Essentials/RazorUp(Pt-P).lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags editing, razor, smart, move, items, (protools-like)
@about
    # Smart Razor: Move Areas Up (ProTools-like)

    This script enhances REAPER’s native:
    **"Razor edit: Move areas up without contents"**

    ## 🟦 Behavior

    - If Razor Areas already exist → moves them up.
    - If no Razor Areas exist but media items are selected →
      automatically runs **"Razor edit: Enclose media items"**
      before moving the areas up.
    - If nothing is selected → no action.

    ## 🟩 Purpose

    Streamlines vertical Razor editing by automatically
    handling Razor creation when needed.

    Optimized for keyboard-driven editing workflows.

    ## 🔗 Part of the ProTools_Essentials Suite

    Designed to integrate with the Smart Razor system
    and the TimecodeUI-based nudge environment.
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
    -- Move Razor Areas up
    reaper.Main_OnCommand(42402, 0)

elseif selectedItemCount > 0 then
    -- Enclose selected items in Razor Area
    reaper.Main_OnCommand(42630, 0)
    -- Then move up
    reaper.Main_OnCommand(42402, 0)
end

reaper.Undo_EndBlock("Smart Razor: Move Up", -1)

