--[[
@description Track / Envelope Display (ImGui helper, PT-like)
@version 1.0 (2025-12-08)
@author Mariow
@changelog
  v1.0 (2025-12-08)
  - Initial release
  - Shows selected envelope name, or track name if no envelope is selected
  - Lightweight ImGui floating window
@provides
  [main] ProTools_Essentials/ViewNameEnvelope(imGui).lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags envelope, track, display, imgui, helper, prot tools
@about
  # Track / Envelope Display (ImGui helper)
  Small ImGui window displaying:
  - The selected envelope name (if any)
  - Otherwise the selected track name

  Useful when working with ProTools-like envelope cycling scripts,  
  providing instant visual feedback without cluttering the arrange view.
--]]


local reaper = reaper
local ctx = reaper.ImGui_CreateContext('Track/Envelope Display')

local FONT = reaper.ImGui_CreateFont('sans-serif', 16)
reaper.ImGui_Attach(ctx, FONT)

----------------------------------------
-- Obtenir enveloppe sélectionnée
----------------------------------------
local function GetSelectedEnvelope()
    local env = reaper.GetSelectedEnvelope(0)
    if not env then return nil end

    local _, envName = reaper.GetEnvelopeName(env, "")
    return env, envName
end

----------------------------------------
-- Obtenir piste sélectionnée
----------------------------------------
local function GetSelectedTrack()
    local track = reaper.GetSelectedTrack(0, 0)
    if not track then return nil end

    local _, name = reaper.GetTrackName(track)
    return track, name
end

----------------------------------------
-- Boucle d'affichage
----------------------------------------
local function Loop()
    reaper.ImGui_PushFont(ctx, FONT,12)

    -- Première ouverture → taille automatique
    reaper.ImGui_SetNextWindowSize(ctx, 250, 80, reaper.ImGui_Cond_FirstUseEver())

    local visible, open = reaper.ImGui_Begin(ctx, 'Track/Envelope', true)
    if visible then
        
        local env, envName = GetSelectedEnvelope()

        if env then
            -- Affiche l'enveloppe sélectionnée
            --reaper.ImGui_Text(ctx, "Enveloppe :")
            --reaper.ImGui_Separator(ctx)
            reaper.ImGui_Text(ctx, envName)

        else
            -- Affiche la piste si aucune enveloppe
            local track, trackName = GetSelectedTrack()

            if track then
                --reaper.ImGui_Text(ctx, "Piste :")
                --reaper.ImGui_Separator(ctx)
                reaper.ImGui_Text(ctx, trackName)
            else
                reaper.ImGui_Text(ctx, "Aucune piste sélectionnée")
            end
        end

        reaper.ImGui_End(ctx)
    end

    reaper.ImGui_PopFont(ctx)

    if open then
        reaper.defer(Loop)
    end
end

----------------------------------------
-- RUN
----------------------------------------
reaper.defer(Loop)

