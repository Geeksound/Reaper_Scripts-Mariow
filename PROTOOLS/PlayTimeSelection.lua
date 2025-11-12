--[[
@description PlayTimeSelection
@version 1.0
@author Mariow
@changelog
  v1.0 - 2025-11-12
    - Initial implementation of GoTo TimeSel and Play
    - Disables preroll if active
    - Saves the current Edit Cursor position (SWS) before jumping to Time Selection start
    - Automatically restores the Edit Cursor after playback stops
    - Plays from the Edit Cursor if no Time Selection is defined
@provides
  [main] PROTOOLS/PlayTimeSelection.lua
@about
  # GoTo Time Selection and Play (Reaper, Pro Tools style)

  This script performs the following actions:

  1. Disables REAPER preroll (command 41818) if it is currently active.
  2. Saves the current Edit Cursor position to SWS slot 1 for later restoration.
  3. Checks if a Time Selection is defined:
     - If yes, moves the play position to the start of the Time Selection.
     - If no, starts playback from the current Edit Cursor position.
  4. Starts playback immediately (command 1007).
  5. Continuously monitors playback; once playback stops, restores the Edit Cursor to its original position using SWS slot 1.

  ## Use case
  - Ideal for working with Time Selections without losing the original Edit Cursor.
  - Mimics Pro Tools behavior where playback can be triggered from Time Selection or Edit Cursor independently.
  - Ensures that the Edit Cursor is restored, maintaining workflow continuity.
  - Disabling preroll avoids accidental playback before the Time Selection or Edit Cursor.

  ## Requirements
  - REAPER v6.80+
  - SWS Extension installed for cursor save/restore slots
--]] 

local prerollCmd = 41818 -- Toggle preroll
local saveCmd = reaper.NamedCommandLookup("_BR_SAVE_CURSOR_POS_SLOT_1")
local restoreCmd = reaper.NamedCommandLookup("_BR_RESTORE_CURSOR_POS_SLOT_1")

-- Désactiver le preroll si activé
if reaper.GetToggleCommandState(prerollCmd) == 1 then
    reaper.Main_OnCommand(prerollCmd, 0)
end

-- Sauvegarder la position actuelle de l'Edit Cursor
reaper.Main_OnCommand(saveCmd, 0)

-- Lire la Time Selection
local startTime, endTime = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)

-- Choisir la position de lecture
local playPos = (startTime ~= endTime) and startTime or reaper.GetCursorPosition()

-- Aller à la position choisie
reaper.SetEditCurPos(playPos, true, false)

-- Jouer
reaper.Main_OnCommand(1007, 0)

-- Restaurer le curseur après arrêt
local function restoreCursor()
    if reaper.GetPlayState() == 0 then
        reaper.Main_OnCommand(restoreCmd, 0)
        return
    end
    reaper.defer(restoreCursor)
end

reaper.defer(restoreCursor)

