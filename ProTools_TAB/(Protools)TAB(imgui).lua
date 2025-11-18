--[[
@description ProTools TAB - Main ImGui Controller (Fade / TabToTransient + ALT/SHIFT actions)
@version 1.0
@author Mariow
@changelog
    v1.0 (2025-06-07)
    - Initial release
@provides
    [main] ProTools_TAB/(Protools)TAB(imgui).lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags protools, tab, transient, fade, editing, gui, imgui
@about
    # ProTools TAB - Main ImGui Controller
    
    This script is the **core of the ProTools TAB system**.  
    It provides an ImGui interface showing the current states of:
    
    - **Fade**
    - **TabToTransient**
    
    It accurately reproduces the behavior of the TAB button in Pro Tools using:
    
    ## 🖱️ Mouse controls
    - **Normal click** → Toggles Fade  
    - **ALT + click** → Enables TabToTransient and disables Fade  
    - **SHIFT + click** → Opens REAPER’s internal “Transient Detection” window
    
    ## 🔗 Full synchronization
    This script continuously reads the values stored in `ExtState` by the other scripts
    (toolbar buttons and keyboard shortcuts), keeping the interface fully synchronized.
    
    It also updates toolbar button states and reacts to the external flag
    “ALT_CLICK_REQUESTED”, sent by other scripts to simulate an ALT-click.
    
    This is the visual and logical centerpiece of the entire “ProTools-like TAB”
    workflow inside REAPER.
--]]

----------------------------------------
-- TOOLTIP helper
----------------------------------------
local function ImGui_HelpMarker(ctx, desc)
    if reaper.ImGui_IsItemHovered(ctx) then
        reaper.ImGui_BeginTooltip(ctx)
        reaper.ImGui_PushTextWrapPos(ctx, reaper.ImGui_GetFontSize(ctx) * 35)
        if reaper.ImGui_TextUnformatted then
            reaper.ImGui_TextUnformatted(ctx, desc)
        else
            reaper.ImGui_Text(ctx, desc)
        end
        reaper.ImGui_PopTextWrapPos(ctx)
        reaper.ImGui_EndTooltip(ctx)
    end
end

local Texte1 = "TAB functions like in Protools\nPress [ALT] to activate Tab to Transient\nPress [SHIFT] to open Transient Detection"

local ctx = reaper.ImGui_CreateContext('ProTools TAB')

local namespace = "ProTools_TAB"

local fade_enabled = (reaper.GetExtState(namespace, "Fade") == "1")
local tab_to_transient = (reaper.GetExtState(namespace, "TabToTransient") == "1")

local show_window = true

----------------------------------------
-- MAIN
----------------------------------------
local function main()
    -- 🔵 Rafraîchir les états à chaque tour
    fade_enabled = (reaper.GetExtState(namespace, "Fade") == "1")
    tab_to_transient = (reaper.GetExtState(namespace, "TabToTransient") == "1")

    -- 🔵 Check du signal ALT_CLICK_REQUESTED
    local external = reaper.GetExtState(namespace, "ALT_CLICK_REQUESTED") == "1"
    if external then
        tab_to_transient = true
        fade_enabled = false
        reaper.SetExtState(namespace, "TabToTransient", "1", true)
        reaper.SetExtState(namespace, "Fade", "0", true)
        reaper.SetExtState(namespace, "ALT_CLICK_REQUESTED", "0", false)
    end

    -- 🔵 IMGUI
    reaper.ImGui_SetNextWindowSize(ctx, 200, 60, reaper.ImGui_Cond_FirstUseEver())
    local visible, open = reaper.ImGui_Begin(ctx, 'TAB', true)

    if visible then
        local pushed = false
        if tab_to_transient then
            pushed = true
            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(),        0xFF6600FF)
            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0xFF7733FF)
            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(),  0xCC5500FF)
        end

        -- Check modifiers
        local mods = reaper.ImGui_GetKeyMods(ctx)
        local isAlt   = (mods & reaper.ImGui_Mod_Alt()) ~= 0
        local isShift = (mods & reaper.ImGui_Mod_Shift()) ~= 0

        local label = ""
        if tab_to_transient then
            label = ">T"
        else
            label = fade_enabled and "[/   \\]" or "[   ]"
        end

        local clicked = reaper.ImGui_Button(ctx, label, 50, 30)
        ImGui_HelpMarker(ctx, Texte1)

        if clicked then
            -- Récupérer contexte du bouton ImGui pour toolbar
            local _, _, sectionID, commandID = reaper.get_action_context()

            local fade_commandID = reaper.NamedCommandLookup("_RS2d59b548b081423aba5dd398d28248e0299189a2") -- "RS1"
            local transient_commandID = reaper.NamedCommandLookup("_RS36d30cfe1671aaa3a7c08bfebbce56c43dae2c20") -- RS2

            if isAlt then
                -- ALT+CLICK → TabToTransient
                tab_to_transient = true
                fade_enabled = false
                reaper.SetExtState(namespace, "TabToTransient", "1", true)
                reaper.SetExtState(namespace, "Fade", "0", true)

                -- Toolbar update
                if transient_commandID then
                    reaper.SetToggleCommandState(0, transient_commandID, 1)
                    reaper.RefreshToolbar2(0, transient_commandID)
                end
                if fade_commandID then
                    reaper.SetToggleCommandState(0, fade_commandID, 0)
                    reaper.RefreshToolbar2(0, fade_commandID)
                end

            elseif isShift then
                -- SHIFT+CLICK → Transient Detection
                reaper.Main_OnCommand(41208, 0)

            else
                -- CLICK normal → toggle Fade
                fade_enabled = not fade_enabled
                tab_to_transient = false
                reaper.SetExtState(namespace, "Fade", fade_enabled and "1" or "0", true)
                reaper.SetExtState(namespace, "TabToTransient", "0", true)

                -- Toolbar update
                if fade_commandID then
                    reaper.SetToggleCommandState(0, fade_commandID, fade_enabled and 1 or 0)
                    reaper.RefreshToolbar2(0, fade_commandID)
                end
                if transient_commandID then
                    reaper.SetToggleCommandState(0, transient_commandID, 0)
                    reaper.RefreshToolbar2(0, transient_commandID)
                end
            end
        end

        if pushed then
            reaper.ImGui_PopStyleColor(ctx, 3)
        end

        reaper.ImGui_End(ctx)
    end

    if not open then show_window = false end
end

----------------------------------------
-- LOOP
----------------------------------------
local function loop()
    if show_window then
        main()
        reaper.defer(loop)
    end
end

loop()

