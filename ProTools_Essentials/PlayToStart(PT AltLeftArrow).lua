--[[
@description Play from pre-roll to the start of Time Selection (ProTools-like)
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-06-07)
  - Initial release
@provides
  [main] ProTools_Essentials/PlayToStart(PT AltLeftArrow).lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags editing, transport, playback, (protools-like)
@about
  # PlayToStart (ProTools-like)
  Plays from a pre-roll amount up to the beginning of the current Time Selection,
  emulating Pro Tools' "Play to In" style behavior with automatic stop at the In point.
--]]

-- Valeur effective de Pre-Roll
local enablePre = reaper.GetExtState("RS_PrePostRoll", "EnablePreRoll") == "true"
local preRoll = enablePre and (tonumber(reaper.GetExtState("RS_PrePostRoll", "PreRoll")) or 2.0) or 2.0

-- Time Selection
local timeSelStart, timeSelEnd = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
if timeSelStart == timeSelEnd then timeSelStart = reaper.GetCursorPosition() end

-- Calcul position de départ
local playStart = math.max(0, timeSelStart - preRoll)
reaper.SetEditCurPos(playStart, false, false)
reaper.OnPlayButton()

-- Stop automatique au début de la Time Selection
local function stopAtTimeSelStart()
    if reaper.GetPlayPosition() >= timeSelStart then
        reaper.OnStopButton()
        return
    end
    reaper.defer(stopAtTimeSelStart)
end

stopAtTimeSelStart()


