--[[
@description Toggle Link Razor Edit to Track Selection (ProTools-like)
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-06-07)
  - Initial release: links Razor Edit areas to track selection (toggle)
@provides
  [main] ProTools_Linking/Geeksound_ToggleLink-RazorToTracks(PT like).lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags razor edit, tracks, selection, linking, (protools-like)
@about
  # Toggle Link Razor Edit to Track Selection (ProTools-like)

  This script toggles a behavior where tracks containing Razor Edit areas
  are automatically selected while other tracks are deselected.

  This mimics the Pro Tools workflow where edit selections implicitly
  define the active tracks for editing operations.

  **Important:** This script is intended to be used with a toolbar button.
  When triggered, it will toggle the Track Selection linkage ON or OFF.
  It is not meant to be launched automatically at startup; instead,
  use the companion startup script (Geeksound_Startup-RazorLinks)
  to activate it safely during session startup.

  Designed for editing workflows where Razor Edits are used
  as a primary selection tool.
--]]

local SECTION = "Mariow_Scripts"
local KEY     = "RazorAffectsTrack"

local _, _, sectionID, cmdID = reaper.get_action_context()
if type(sectionID) ~= "number" then sectionID = nil end
if type(cmdID)    ~= "number" then cmdID = nil end

local function razor_follow_track()
    if reaper.GetExtState(SECTION, KEY) ~= "ON" then return end

    local track_count = reaper.CountTracks(0)
    local razor_found = false

    -- Vérifier si une Razor Edit existe
    for t = 0, track_count-1 do
        local track = reaper.GetTrack(0, t)
        local _, razor_string = reaper.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", "", false)
        if razor_string ~= nil and razor_string ~= "" then
            razor_found = true
            break
        end
    end

    -- Si au moins une Razor Edit existe
    if razor_found then
        -- Deselectionner toutes les pistes
        for t = 0, track_count-1 do
            local track = reaper.GetTrack(0, t)
            reaper.SetTrackSelected(track, false)
        end

        -- Selectionner uniquement les pistes avec Razor Edit
        for t = 0, track_count-1 do
            local track = reaper.GetTrack(0, t)
            local _, razor_string = reaper.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", "", false)
            if razor_string ~= nil and razor_string ~= "" then
                reaper.SetTrackSelected(track, true)
            end
        end
    end

    reaper.defer(razor_follow_track)
end

local state = reaper.GetExtState(SECTION, KEY)

if state == "" or state == "OFF" then
    reaper.SetExtState(SECTION, KEY, "ON", false)
    if sectionID and cmdID then
        reaper.SetToggleCommandState(sectionID, cmdID, 1)
        reaper.RefreshToolbar2(sectionID, cmdID)
    end
    razor_follow_track()
else
    reaper.SetExtState(SECTION, KEY, "OFF", false)
    if sectionID and cmdID then
        reaper.SetToggleCommandState(sectionID, cmdID, 0)
        reaper.RefreshToolbar2(sectionID, cmdID)
    end
end
