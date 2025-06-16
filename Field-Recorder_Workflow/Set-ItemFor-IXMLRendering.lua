--[[
@description Set-ItemFor-IXMLRendering
@version 1.0
@author Mariow
@license MIT
@changelog
  v1.0 (2025-06-08)
  - Initial release
@provides
  [main] Field-Recorder_Workflow/Set-ItemFor-IXMLRendering.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags dialogue conformation workflow Fieldrecording Track rushs raw files matching conforming
@about
  # Set-ItemFor-IXMLRendering

  This script comes after AAF importing files (ideally from Vordio).
  It prepares item names and notes for the injection of iXML tags concerning SCENE/TAKE and TRACKNAME during a specific rendering.

  - Modifies item names and item notes based on the content injected by VORDIO during AAF export.
  - May be followed by item rendering with iXML metadata injection (ItemName > SCENE and ItemNotes > Take).
  - Improves field recording track matching by SCENE & TAKE.
  - Advanced dialogue field recorder track matching and organizing, similar to PROTOOLS.

  This script was developed with the help of GitHub Copilot.
--]]


reaper.Undo_BeginBlock()

local sel_cnt = reaper.CountSelectedMediaItems(0)
if sel_cnt == 0 then
  reaper.ShowMessageBox("Aucun item sélectionné.", "Erreur", 0)
  return
end

local ok_scene, fail_scene = 0, 0
local ok_take, fail_take = 0, 0

for i = 0, sel_cnt - 1 do
  local item = reaper.GetSelectedMediaItem(0, i)
  local take = reaper.GetActiveTake(item)

  if take then
    local _, notes = reaper.GetSetMediaItemInfo_String(item, "P_NOTES", "", false)

    -- === Étape 1 : Renommer take avec valeur après "Scene:" ===
    local scene_val = notes:match("Scene%s*:%s*(%S+)")
    if scene_val then
      reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", scene_val, true)
      ok_scene = ok_scene + 1
    else
      fail_scene = fail_scene + 1
    end

    -- === Étape 2 : Ne garder que la valeur après "Take:" dans les notes ===
    local take_val = notes:match("Take%s*:%s*(%S+)")
    if take_val then
      reaper.GetSetMediaItemInfo_String(item, "P_NOTES", take_val, true)
      ok_take = ok_take + 1
    else
      fail_take = fail_take + 1
    end
  else
    fail_scene = fail_scene + 1
    fail_take = fail_take + 1
  end
end

reaper.UpdateArrange()
reaper.Undo_EndBlock("Renommer take avec Scene + Nettoyer notes avec Take", -1)

-- Optionnel : afficher un résumé dans la console
--[[
reaper.ShowConsoleMsg(string.format(
  "Script terminé.\nRenommage 'Scene:' → Take : %d réussis, %d échoués\nNettoyage 'Take:' → Notes : %d réussis, %d échoués\n",
  ok_scene, fail_scene, ok_take, fail_take))
]]



