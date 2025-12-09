--[[
@description Play through the end of Time Selection with pre/post-roll (ProTools-like)
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-06-07)
  - Initial release
@provides
  [main] ProTools_Essentials/PlayThruEnd(PT AltCmdRightArrow).lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags editing, transport, playback, (protools-like)
@about
  # PlayThruEnd (ProTools-like)
  Plays from pre-roll through to the end of the Time Selection,
  continuing into post-roll — emulating the Pro Tools “Play Thru Out” behavior.
--]]

-- Vérifier si Pre/Post Roll sont activés
local enablePre  = reaper.GetExtState("RS_PrePostRoll", "EnablePreRoll")  == "true"
local enablePost = reaper.GetExtState("RS_PrePostRoll", "EnablePostRoll") == "true"

-- Valeurs effectives
local preRoll  = enablePre  and (tonumber(reaper.GetExtState("RS_PrePostRoll", "PreRoll"))  or 2.0) or 2.0
local postRoll = enablePost and (tonumber(reaper.GetExtState("RS_PrePostRoll", "PostRoll")) or 2.0) or 2.0

-- Obtenir la Time Selection
local _, timeSelEnd = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
if _ == timeSelEnd then timeSelEnd = reaper.GetProjectLength(0) end

-- Calculer positions de lecture
local playStart = math.max(0, timeSelEnd - preRoll)
local playStop  = timeSelEnd + postRoll

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


