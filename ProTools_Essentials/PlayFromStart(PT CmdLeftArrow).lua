--[[
@description Play from the start of Time Selection with post-roll (ProTools-like)
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-06-07)
  - Initial release
@provides
  [main] ProTools_Essentials/PlayFromStart(PT CmdLeftArrow).lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags editing, transport, playback, (protools-like)
@about
  # PlayFromStart (ProTools-like)
  Plays from the start of the Time Selection and continues into a post-roll,
  emulating Pro Tools' "Play From In" behavior with automatic stop after post-roll.
--]]

-- Vérifier si Post-Roll est activé
local enablePost = reaper.GetExtState("RS_PrePostRoll", "EnablePostRoll") == "true"

-- Valeur effective de Post-Roll
local postRoll = enablePost and (tonumber(reaper.GetExtState("RS_PrePostRoll", "PostRoll")) or 2.0) or 2.0

-- Obtenir la Time Selection
local timeSelStart, timeSelEnd = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
if timeSelStart == timeSelEnd then timeSelStart = 0 end

-- Calculer la position d'arrêt
local stopPos = timeSelStart + postRoll

-- Placer le curseur et lancer la lecture
reaper.SetEditCurPos(timeSelStart, false, false)
reaper.OnPlayButton()

-- Fonction pour arrêter après le Post-Roll
local function stopAfterPostRoll()
    if reaper.GetPlayPosition() >= stopPos then
        reaper.OnStopButton()
        return
    end
    reaper.defer(stopAfterPostRoll)
end

stopAfterPostRoll()


