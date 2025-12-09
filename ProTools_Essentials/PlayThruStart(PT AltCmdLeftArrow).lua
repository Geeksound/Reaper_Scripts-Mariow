--[[
@description Play through the start of Time Selection with pre/post-roll (ProTools-like)
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-06-07)
  - Initial release
@provides
  [main] ProTools_Essentials/PlayThruStart(PT AltCmdLeftArrow).lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags editing, transport, playback, (protools-like)
@about
  # PlayThruStart (ProTools-like)
  Plays from pre-roll, passes through the start of the Time Selection,
  and continues into post-roll — emulating the Pro Tools “Play Thru In” behavior.
--]]

-- Vérifier si Pre/Post Roll est activé
local enablePre  = reaper.GetExtState("RS_PrePostRoll", "EnablePreRoll")  == "true"
local enablePost = reaper.GetExtState("RS_PrePostRoll", "EnablePostRoll") == "true"

-- Valeurs effectives
local preRoll  = enablePre  and (tonumber(reaper.GetExtState("RS_PrePostRoll", "PreRoll"))  or 2.0) or 2.0
local postRoll = enablePost and (tonumber(reaper.GetExtState("RS_PrePostRoll", "PostRoll")) or 2.0) or 2.0

-- Obtenir le début de la Time Selection
local timeSelStart, _ = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
if timeSelStart == _ then timeSelStart = reaper.GetCursorPosition() end

-- Calculer les positions de lecture
local playStart = math.max(0, timeSelStart - preRoll)
local playStop  = timeSelStart + postRoll

-- Placer le curseur et lancer la lecture
reaper.SetEditCurPos(playStart, false, false)
reaper.OnPlayButton()

-- Arrêt automatique après le Post-Roll
local function stopAfterPostRoll()
    if reaper.GetPlayPosition() >= playStop then
        reaper.OnStopButton()
        return
    end
    reaper.defer(stopAfterPostRoll)
end

stopAfterPostRoll()


