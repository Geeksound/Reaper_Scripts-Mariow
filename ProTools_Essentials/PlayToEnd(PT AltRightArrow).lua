--[[
@description Play from pre-roll to the end of Time Selection (ProTools-like)
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-06-07)
  - Initial release
@provides
  [main] ProTools_Essentials/PlayToEnd(PT AltRightArrow).lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags editing, transport, playback, (protools-like)
@about
  # PlayToEnd (ProTools-like)
  Plays from a pre-roll amount and stops automatically at the end
  of the current Time Selection, emulating Pro Tools’ "Play To Out".
--]]

-- Vérifier si Pre-Roll est activé
local enablePre = reaper.GetExtState("RS_PrePostRoll", "EnablePreRoll") == "true"

-- Valeur effective de Pre-Roll
local preRoll = enablePre and (tonumber(reaper.GetExtState("RS_PrePostRoll", "PreRoll")) or 2.0) or 2.0

-- Obtenir la Time Selection
local _, timeSelEnd = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
if _ == timeSelEnd then timeSelEnd = reaper.GetProjectLength(0) end

-- Calculer la position de départ
local playStart = math.max(0, timeSelEnd - preRoll)

-- Placer le curseur et lancer la lecture
reaper.SetEditCurPos(playStart, false, false)
reaper.OnPlayButton()

-- Arrêt automatique à la fin de la Time Selection
local function stopAtEnd()
    if reaper.GetPlayPosition() >= timeSelEnd then
        reaper.OnStopButton()
        return
    end
    reaper.defer(stopAtEnd)
end

stopAtEnd()


