--[[
@description Play from the end of Time Selection with post-roll (ProTools-like)
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-06-07)
  - Initial release
@provides
  [main] ProTools_Essentials/PlayFromEnd(PT cmd RightArrow).lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags editing, transport, playback, (protools-like)
@about
  # PlayFromEnd (ProTools-like)
  Plays from the end of the Time Selection and continues into a post-roll,
  emulating Pro Tools’ "Play From Out" behavior with automatic stop.
--]]

-- Vérifier si Post-Roll est activé
local enablePost = reaper.GetExtState("RS_PrePostRoll", "EnablePostRoll") == "true"

-- Valeur effective de Post-Roll
local postRoll = enablePost and (tonumber(reaper.GetExtState("RS_PrePostRoll", "PostRoll")) or 2.0) or 2.0

-- Obtenir la Time Selection
local _, timeSelEnd = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
if _ == timeSelEnd then timeSelEnd = reaper.GetProjectLength(0) end

-- Calculer la position d'arrêt
local stopPos = timeSelEnd + postRoll

-- Placer le curseur et lancer la lecture
reaper.SetEditCurPos(timeSelEnd, false, false)
reaper.OnPlayButton()

-- Arrêt automatique après le Post-Roll
local function stopAfterPostRoll()
    if reaper.GetPlayPosition() >= stopPos then
        reaper.OnStopButton()
        return
    end
    reaper.defer(stopAfterPostRoll)
end

stopAfterPostRoll()


