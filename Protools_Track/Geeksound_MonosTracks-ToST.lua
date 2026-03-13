--[[
@description Convert mono tracks to stereo takes (ProTools-like)
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-06-07)
  - Initial release
@provides
  [main] Protools_Track/MonosTracks-ToST.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags editing, tracks, items, takes, implode, glue, (protools-like)
@about
  # MonosTracks-ToST (ProTools-like)
  Converts multiple mono items on a track into a stereo take structure:
  1. Selects all items on the track  
  2. Uses the Xenakios/SWS action  
     **"Implode items to takes and pan symmetrically"**  
  3. Individually glues each resulting take while preserving  
     the original take name and color (without generating double takes)  
  4. Refreshes the arrange view

  This behavior emulates Pro Tools workflows for consolidating mono sources 
  into structured stereo takes.
--]]


local function Msg(s) reaper.ShowConsoleMsg(tostring(s).."\n") end

-- PART 1 : select all items in track
reaper.Main_OnCommand(40421, 0)

-- PART 1b : Xenakios/SWS: Implode items to takes and pan symmetrically
local cmd_implode = reaper.NamedCommandLookup("_XENAKIOS_IMPLODEITEMSPANSYMMETRICALLY")
if cmd_implode ~= 0 then
  reaper.Main_OnCommand(cmd_implode, 0)
else
  -- si la commande n'existe pas, on continue quand même (mais prévenir peut aider)
  -- Msg("Commande XENAKIOS_IMPLODEITEMSPANSYMMETRICALLY introuvable")
end

-- PART 2 : Glue independently — traiter chaque item sélectionné courant un par un
local function glue_each_selected_item_restore_name_color()
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)

  -- Tant qu'il y a au moins un item sélectionné, traiter le premier (index 0)
  while reaper.CountSelectedMediaItems(0) > 0 do
    -- prendre le premier item sélectionné courant
    local item = reaper.GetSelectedMediaItem(0, 0)
    if not item then break end

    -- obtenir l'index du take actif pour cet item (I_CURTAKE retourne l'index)
    local cur_take_index = reaper.GetMediaItemInfo_Value(item, "I_CURTAKE")
    local take_index = math.floor(cur_take_index + 0.5) -- sécurité (entier)
    local take = reaper.GetMediaItemTake(item, take_index)

    -- récupérer nom du take (si présent)
    local take_name = ""
    if take then
      _, take_name = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)
    end

    -- récupérer couleur (priorité au take, sinon couleur de l'item)
    local take_color = 0
    if take then take_color = reaper.GetMediaItemTakeInfo_Value(take, "I_CUSTOMCOLOR") end
    local item_color = reaper.GetMediaItemInfo_Value(item, "I_CUSTOMCOLOR")
    local color = (take_color ~= 0 and take_color) or item_color

    -- effectuer le Glue (sans time selection)
    reaper.Main_OnCommand(40362, 0) -- Item: Glue items (create new take etc.)

    -- après le glue, l'item nouvellement créé est sélectionné -> récupérer et restaurer nom/couleur
    local new_item = reaper.GetSelectedMediaItem(0, 0)
    if new_item then
      local new_take = reaper.GetActiveTake(new_item)
      if new_take and take_name and take_name ~= "" then
        reaper.GetSetMediaItemTakeInfo_String(new_take, "P_NAME", take_name, true)
      end
      if color and color ~= 0 then
        reaper.SetMediaItemInfo_Value(new_item, "I_CUSTOMCOLOR", color)
      end
      -- dé-sélectionner cet item (pour avancer sur les items restants)
      reaper.SetMediaItemSelected(new_item, false)
    else
      -- si pas d'item retrouvé (peu probable), sortir pour éviter boucle infinie
      break
    end
  end

  reaper.PreventUIRefresh(-1)
  reaper.Undo_EndBlock("Glue selected items independently (restore name & color)", -1)
end

glue_each_selected_item_restore_name_color()


-- refresh arrange
reaper.UpdateArrange()

