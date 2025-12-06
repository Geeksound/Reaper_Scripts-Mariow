--[[
@description Trim item end to Time Selection on selected track (ProTools-like)
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-06-07)
  - Initial release
@provides
  [main] Protools_Edit/EndToFillSelection.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags editing, items, (protools-like)
@about
  # EndToFillSelection (ProTools-like)
  Trims the *end* of items to the end of the current Time Selection
  on the selected track, emulating Pro Tools’ "Trim End to Fill Selection".
--]]

local track = reaper.GetSelectedTrack(0,0)
if not track then return end

-- Sauvegarde la position du curseur
local cur_pos = reaper.GetCursorPosition()

-- 1️⃣ Sélectionne tous les items de la piste dans la Time Selection
reaper.Main_OnCommand(40718,0) -- Item: Select all items on selected tracks in current time selection

-- 3️⃣ Va à la fin de la Time Selection et trim le end
reaper.Main_OnCommand(40631,0) -- Go to end of time selection
reaper.Main_OnCommand(41311,0) -- Item edit: Trim right edge of item to edit cursor

-- 4️⃣ Supprime la Time Selection
reaper.Main_OnCommand(40635,0) -- Time selection: Remove

-- 5️⃣ Désélectionne tous les items
reaper.SelectAllMediaItems(0,false)

-- Restaure le curseur
reaper.SetEditCurPos(cur_pos,false,false)

