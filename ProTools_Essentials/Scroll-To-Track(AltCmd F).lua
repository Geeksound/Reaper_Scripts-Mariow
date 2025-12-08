--[[
@description Scroll to a selected track by name (ProTools-like)
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-11-25)
  - Initial release: scrolls to track matching filter text using Alt+Cmd F workflow
@provides
  [main] ProTools_Essentials/Mariow Scroll-To-Track(AltCmd F).lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags navigation, tracks, filtering, (protools-like)
@about
  # Scroll-To-Track (ProTools-like)
  Opens a filterable list of tracks and scrolls the arrange view
  to the selected track, emulating Pro Tools' Alt+Cmd+F behavior.
--]]

if not reaper.ImGui_CreateContext then
    reaper.MB("⚠️ ReaImGui is not installed or enabled.\nInstall it via ReaPack.", "Error", 0)
    return
end

local ctx = reaper.ImGui_CreateContext("Scroll-To-Track")
local filter = ""
local selected_index = 1
local filtered = {}
local open = true

-- Récupération des pistes
local function GetTrackList()
    local t = {}
    for i = 0, reaper.CountTracks(0)-1 do
        local tr = reaper.GetTrack(0,i)
        local _, name = reaper.GetTrackName(tr)
        table.insert(t, {tr=tr, name=name, index=i})
    end
    return t
end
local tracks = GetTrackList()

-- Filtrer selon le texte
local function UpdateFiltered()
    filtered = {}
    for _, t in ipairs(tracks) do
        if filter ~= "" and t.name:lower():find(filter:lower(),1,true) then
            table.insert(filtered, t)
        end
    end
    selected_index = (#filtered > 0) and 1 or 1
end
UpdateFiltered()

-- Scroll vers la piste
local function ScrollToTrack(t)
    reaper.Main_OnCommand(40297,0) -- Unselect all tracks
    reaper.SetTrackSelected(t.tr,true)
    reaper.Main_OnCommand(40913,0) -- Scroll selected tracks into view
end

-- Loop ImGui
local function loop()
    if not open then
        if reaper.ImGui_DestroyContext then reaper.ImGui_DestroyContext(ctx) end
        return
    end

    reaper.ImGui_SetNextWindowSize(ctx, 400, 250, reaper.ImGui_Cond_FirstUseEver())
    local visible
    visible, open = reaper.ImGui_Begin(ctx,"Scroll-To-Track", open, reaper.ImGui_WindowFlags_AlwaysAutoResize())

    if visible then
        local changed
        changed, filter = reaper.ImGui_InputText(ctx,"Filter",filter,256)
        if changed then UpdateFiltered() end

        -- Liste des pistes filtrées
        if #filtered > 0 then
            for i, t in ipairs(filtered) do
                if reaper.ImGui_Selectable(ctx, t.name, selected_index == i) then
                    selected_index = i
                    ScrollToTrack(t)
                    open = false
                end
            end
        else
            reaper.ImGui_Text(ctx,"No tracks match")
        end

        -- Navigation clavier
        if #filtered > 0 then
            if reaper.ImGui_IsKeyPressed(ctx,reaper.ImGui_Key_UpArrow()) then
                selected_index = math.max(1,selected_index-1)
            elseif reaper.ImGui_IsKeyPressed(ctx,reaper.ImGui_Key_DownArrow()) then
                selected_index = math.min(#filtered,selected_index+1)
            elseif reaper.ImGui_IsKeyPressed(ctx,reaper.ImGui_Key_Enter()) or
                   reaper.ImGui_IsKeyPressed(ctx,reaper.ImGui_Key_KeypadEnter()) then
                ScrollToTrack(filtered[selected_index])
                open = false
            end
        end

        reaper.ImGui_End(ctx)
    end

    reaper.defer(loop)
end

loop()


