--[[
@description Playloop
@version 1.0
@author Mariow
@changelog
  v1.0 - 2025-11-12
    - Initial implementation of GoTo Loop Start and Play
    - Disables preroll if active
    - Saves the current Edit Cursor position (SWS) before jumping to loop start
    - Automatically restores the Edit Cursor after playback stops
    - Mimics Pro Tools behavior of "Edit Selection vs Loop Points"
@provides
  [main] PROTOOLS/PlayLoop.lua
@about
  # GoTo Loop Start and Play (Reaper, Pro Tools style)

  This script performs the following actions:

  1. Disables REAPER preroll (command 41818) if it is currently active.
  2. Saves the current Edit Cursor position to SWS slot 1, allowing restoration later.
  3. Moves the play position to the start of the current Loop selection (command 40632).
  4. Starts playback immediately (command 1007).
  5. Continuously monitors playback; once playback stops, it restores the Edit Cursor to its original position using SWS slot 1.

  ## Use case
  - Useful for working with Loop Points independently from the Edit Cursor, similar to Pro Tools' "Link/Unlink Timeline & Edit Selection".
  - Ensures that the Edit Cursor is not lost when temporarily jumping to a Loop Start for playback.
  - Disabling preroll avoids accidental pre-roll playback before the Loop Start.

  ## Requirements
  - REAPER v6.80+ 
  - SWS Extension installed for cursor save/restore slots
  - Loop points must be defined for the jump to occur
--]]

local prerollCmd = 41818 -- Toggle preroll
local saveCmd = reaper.NamedCommandLookup("_BR_SAVE_CURSOR_POS_SLOT_1")
local restoreCmd = reaper.NamedCommandLookup("_BR_RESTORE_CURSOR_POS_SLOT_1")

-- Désactiver le preroll si activé
if reaper.GetToggleCommandState(prerollCmd) == 1 then
    reaper.Main_OnCommand(prerollCmd, 0)
end

-- Sauvegarder la position actuelle du curseur
reaper.Main_OnCommand(saveCmd, 0)

-- Aller au début du Loop
reaper.Main_OnCommand(40632, 0)

-- Lancer la lecture
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

