--[[
@description Trim Left Edge of Item to Cursor (ProTools-like Q)
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-11-26)
  - Initial release: trims the left edge of the item under cursor to edit cursor, Pro Tools Q behavior
@provides
  [main] Protools_Edit/Trim-Left-(PT Q).lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags editing, items, trim, (protools-like)
@about
  # Trim Left Edge (ProTools-like)
  Selects the media item under the edit cursor and trims its left edge
  up to the cursor position, mimicking Pro Tools' Q shortcut behavior.
--]]

-- 1. Sélectionner l'item sous le curseur
reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_SELITEMSUNDEDCURSELTX"), 0)

-- 2. Trim bord gauche de l'item jusqu'au curseur
reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_TRIM_LEFTEDGETO_EDCURSOR"), 0)

-- 3. Supprimer la time selection (si existante)
reaper.Main_OnCommand(40289, 0)

reaper.Undo_EndBlock("Trim Left (PT Q)", -1)

