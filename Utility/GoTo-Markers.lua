--[[
@description Go To Marker (ImGui)
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-11-12)
  - Initial release: simple Go To Marker window using ReaImGui
  - Pressing Return/Enter in the Marker input field jumps directly to that marker
  - Minor improvements for ImGui input handling
@provides
  [main] Utility/GoTo-Markers.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags navigation, utility, ImGui, marker
@about
  # Go To Marker (ImGui)
  Simple ReaImGui-based script for REAPER to jump to a marker by number.
  Features:
  - Input field to type marker number
  - Press Enter to jump directly to marker
  - Lightweight and minimal interface
--]]

local reaper = reaper
local ctx = reaper.ImGui_CreateContext('GoTo-Markers (by Mariow)')
local marker_input = ""

-- Fonction : aller au marqueur indiqué
function go_to_marker(num)
    num = tonumber(num)
    if not num then return end
    local _, _, pos = reaper.EnumProjectMarkers(num - 1)
    if pos then
        reaper.SetEditCurPos(pos, true, true)
    end
end

function loop()
    -- Démarre la fenêtre
    reaper.ImGui_SetNextWindowSize(ctx, 300, 80, reaper.ImGui_Cond_FirstUseEver())
    local visible, open = reaper.ImGui_Begin(ctx, 'GoTo-Markers (by Mariow)', true)

    if visible then
        reaper.ImGui_Text(ctx, "Go-To Marker")
        reaper.ImGui_SetNextItemWidth(ctx, 30)
        reaper.ImGui_SameLine(ctx)

        local changed_marker, marker_input_entered = reaper.ImGui_InputText(
            ctx,
            "##MarkerInput",
            marker_input,
            reaper.ImGui_InputTextFlags_EnterReturnsTrue()
        )

        if changed_marker then
            marker_input = marker_input_entered
        end

        if reaper.ImGui_IsItemDeactivatedAfterEdit(ctx) then
            go_to_marker(marker_input)
        end
        reaper.ImGui_SameLine(ctx)
        reaper.ImGui_Text(ctx, "(Press Enter)")
        reaper.ImGui_End(ctx)
    end
    
    if open then
        reaper.defer(loop)
    else
        -- Certains ReaImGui ne supportent pas DestroyContext
        if reaper.ImGui_DestroyContext then
            reaper.ImGui_DestroyContext(ctx)
        end
    end
end

reaper.defer(loop)

