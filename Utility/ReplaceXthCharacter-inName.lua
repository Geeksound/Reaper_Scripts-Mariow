--[[
@description CharacterText Interchange in Names
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-06-08)
  - Initial Release
@provides
  [main] Utility/ReplaceXthCharacter-inName.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags name, items, editing
@about
  # ReplaceXthCharacter-inName
  Contextual Replacement of a Character or sequence of Characters in Reaper 7.0.
  This script was developed with the help of GitHub Copilot.
--]]

-- Ask the user for the text to replace
local ret1, a_remplacer = reaper.GetUserInputs("Text Replacement", 1, "Text to Replace:", "")
if not ret1 or a_remplacer == "" then return end

-- Demande le nouveau texte
local ret2, remplacant = reaper.GetUserInputs("Text Replacement", 1, "New Text:", "")
if not ret2 then return end

-- Commence une action undo
reaper.Undo_BeginBlock()

-- Applique le remplacement sur tous les items sélectionnés
local num_items = reaper.CountSelectedMediaItems(0)

for i = 0, num_items - 1 do
local item = reaper.GetSelectedMediaItem(0, i)
local take = reaper.GetActiveTake(item)
if take ~= nil then
local nom = reaper.GetTakeName(take)
local nouveau_nom = string.gsub(nom, a_remplacer, remplacant)
reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", nouveau_nom, true)
end
end

-- Termine l'action undo
reaper.Undo_EndBlock("Remplacer texte dans noms d'items", -1)

