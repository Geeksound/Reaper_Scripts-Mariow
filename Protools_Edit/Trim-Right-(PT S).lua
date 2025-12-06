--[[
@description Trim Right Edge of Item to Cursor (ProTools-like)
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-11-26)
  - Initial release: trims the right edge of the item under cursor to edit cursor, Pro Tools S behavior
@provides
  [main] Protools_Edit/Trim-Right-(PT S).lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags editing, items, trim, (protools-like)
@about
  # Trim Right Edge (ProTools-like)
  Selects the media item under the edit cursor and trims its right edge
  up to the cursor position, mimicking Pro Tools' S shortcut behavior.
--]]

reaper.Undo_BeginBlock()

-- 1. Sélectionner l'item sous le curseur
reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_SELITEMSUNDEDCURSELTX"), 0)

-- 2. Trim bord droit de l'item jusqu'au curseur
reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_TRIM_RIGHTEDGETO_EDCURSOR"), 0)

-- 3. Supprimer la time selection (si existante)
reaper.Main_OnCommand(40289, 0)

reaper.Undo_EndBlock("Trim Right (PT S)", -1)

