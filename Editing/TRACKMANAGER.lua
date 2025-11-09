--[[
@description TrackManager
@version 1.3
@author Mariow
@changelog
  V1.3 (2025-11-09)
  - Helpers IMgui and Option [alt]click like in PT
  V1.2 (2025-11-07)
  Check when creating a track that the track name does not already exist.
  v1.1 (2025-10-31)
  - Debug with relaunch on Prefix button

  v1.0 (2025-10-28)
  - Initial release
@provides
  [main] Editing/TRACKMANAGERexpanded.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags tracks, session, palette, management, visualization
@about
  # TrackManager
  Short Version of TRACKMANAGERexpanded
  Harmonious palette and tools for managing and visualizing the state of your session's tracks in Reaper.
  This script should be placed horizontally on the master Track for greater convenience 
--]]


local reaper = reaper
local ctx = reaper.ImGui_CreateContext('Track Manager Color/Manage/View')

local ctx = reaper.ImGui_CreateContext('Interface de boutons complète')
local show_confirm_popup = false

local show_tracks_guide = true  -- état de la case à cocher

------------------------------------ Pour Recharge de Script ------
local info = debug.getinfo(1, 'S')
local script_path = info.source:match("@(.*)")
-- Crée un contexte ImGui
local ctx = reaper.ImGui_CreateContext('Demo Relance')
--------------------------------------------------------------------
----- F I N D ------
local show_tracks_search = false
local search_text = ''
local search_results = {}
--------------------
local prevItemNames = {}
---------------------------
--- Actions au demarrage
-- Fonction locale : supprime les préfixes numériques et symboles au début du nom des pistes
local function delprefixonTrackName()
  for i = 0, reaper.CountTracks(0) - 1 do
    local track = reaper.GetTrack(0, i)
    local retval, trackName = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
    if retval then
      -- Supprime les chiffres et caractères non alphanumériques au début (ex : "01 - Kick" → "Kick")
      local newName = trackName:gsub("^%d+%W*", "")
      -- Supprime les underscores ou autres non alphanumériques restants au début
      newName = newName:gsub("^[_%W]*", "")

      if newName ~= trackName then
        reaper.GetSetMediaTrackInfo_String(track, "P_NAME", newName, true)
      end
    end
  end
  reaper.UpdateArrange()
  createitemsfromtracks()
end
-----------------------------------------------------
------------------------- Helpers ------------------------------------
--========================================
-- 🔹 Help Tooltip Function (compatible with all versions)
--========================================
local function ImGui_HelpMarker(ctx, desc)
    if reaper.ImGui_IsItemHovered(ctx) then
        reaper.ImGui_BeginTooltip(ctx)
        reaper.ImGui_PushTextWrapPos(ctx, reaper.ImGui_GetFontSize(ctx) * 35)
        if reaper.ImGui_TextUnformatted then
            reaper.ImGui_TextUnformatted(ctx, desc)
        else
            reaper.ImGui_Text(ctx, desc)
        end
        reaper.ImGui_PopTextWrapPos(ctx)
        reaper.ImGui_EndTooltip(ctx)
    end
end

-- 🔹 Customizable Help Texts
local Texte1 = "Add TRACK, Otion[ALT] lets you delete Tracks."
local Texte2 = "ADD Spacer, Otion[ALT] lets you delete Spacer after selected Tracks"
local Texte3 = "Move track Down , Otion[ALT] lets you move Track Up inversely"
local Texte4 = "Move track by listing position"
local Texte5 = "Allows alternating between viewing the Track Item and its corresponding track."

------------------------ End HELPERS ---------------------------------

local function StripPrefix(name)
  return name:match("^%s*%d+%s*[-_.]%s*(.+)")
end
---------------------------------
local function CheckItemRenames()
  local selItemCount = reaper.CountSelectedMediaItems(0)
  for i = 0, selItemCount - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    local take = reaper.GetActiveTake(item)
    if take then
      local _, name = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)
      local prevName = prevItemNames[item]

      if name ~= "" and name ~= prevName then
        local trackNumStr, newName = name:match("^%s*(%d+)%s*[-_.]%s*(.+)")
        if trackNumStr and newName then
          local trackIndex = tonumber(trackNumStr)
          local track = reaper.GetTrack(0, trackIndex - 1)
          if track then
            reaper.Undo_BeginBlock()
            reaper.GetSetMediaTrackInfo_String(track, "P_NAME", newName, true)
            reaper.Undo_EndBlock("Auto rename track from item", -1)
          end
        end

        prevItemNames[item] = name
      end
    end
  end

  reaper.defer(CheckItemRenames)
end
---------------------------------
local function InitPrevItemNames()
  local selItemCount = reaper.CountSelectedMediaItems(0)
  for i = 0, selItemCount - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    local take = reaper.GetActiveTake(item)
    if take then
      local _, name = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)
      prevItemNames[item] = name
    end
  end
end
---------------------------------
local prevTrackNames = {}

local function CheckTrackRenames()
  local trackCount = reaper.CountTracks(0)
  for i = 0, trackCount - 1 do
    local track = reaper.GetTrack(0, i)
    local _, name = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
    local prevName = prevTrackNames[track]
    if name ~= prevName then
      if prevName ~= nil then  -- pour éviter l'appel lors de l'initialisation
        createitemsfromtracks()
      end
      prevTrackNames[track] = name
    end
  end

  reaper.defer(CheckTrackRenames)
end
---------------------------------
local function InitPrevTrackNames()
  local trackCount = reaper.CountTracks(0)
  for i = 0, trackCount - 1 do
    local track = reaper.GetTrack(0, i)
    local _, name = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
    prevTrackNames[track] = name
  end
end

InitPrevTrackNames()
CheckTrackRenames()
InitPrevItemNames()
CheckItemRenames()
-------------------------------------- end prog detection 
local function StripPrefix(name)
  return name:match("^%d+%s*%-*%s*(.+)$") or name
end

local function FindTracksGuide()
  local trackCount = reaper.CountTracks(0)
  for i = 0, trackCount - 1 do
    local tr = reaper.GetTrack(0, i)
    local _, name = reaper.GetTrackName(tr)
    if name == "TRACKS" then
      return tr
    end
  end
  return nil
end


------------------------------------------------------------
-- CONFIGURATION
------------------------------------------------------------
local conf = { number_x = 36, palette_y = 1, spacing = 4}
local apply_to_items = false
local apply_to_tracks = true

local btn_size = 19
local first_frame = true

------------------------------------------------------------
-- CONVERSION RGB → BGR
------------------------------------------------------------
local function rgb_to_bgr_int(r,g,b)
  local R = math.floor(r*255 + 0.5)
  local G = math.floor(g*255 + 0.5)
  local B = math.floor(b*255 + 0.5)
  return (B << 16) | (G << 8) | R | 0x1000000
end

------------------------------------------------------------
-- PALETTE COLORS
------------------------------------------------------------
local palette_gui = {
  {0.1,0.2,0.8}, {0.2,0.3,0.9}, {0.3,0.4,1.0}, {0.0,0.5,1.0}, {0.2,0.6,0.9}, {0.3,0.7,0.8}, {0.1,0.8,0.9}, {0.2,0.9,1.0}, {0.0,1.0,1.0},
  {0.0,0.6,0.2}, {0.1,0.7,0.3}, {0.2,0.8,0.4}, {0.0,0.9,0.5}, {0.1,1.0,0.6}, {0.2,0.8,0.2}, {0.3,0.7,0.1}, {0.4,0.6,0.0}, {0.5,0.5,0.0},
  {1.0,1.0,0.0}, {1.0,0.85,0.0}, {1.0,0.8,0.0}, {1.0,0.7,0.0}, {1.0,0.6,0.0}, {1.0,0.5,0.0}, {1.0,0.4,0.0}, {1.0,0.3,0.0}, {1.0,0.0,0.0},
  {0.9,0.8,0.9}, {1.0,0.7,0.9}, {0.8,0.5,0.9}, {0.7,0.1,0.6}, {0.6,0.0,0.5}, {0.5,0.2,0.3}, {0.6,0.3,0.2}, {0.4,0.2,0.1}, {0.3,0.1,0.0}
}

local palette_appliquee = {}
for i, color in ipairs(palette_gui) do
  palette_appliquee[i] = { color[3], color[2], color[1] }
end


------------------------------------------------------------
-- APLLY COLORS
------------------------------------------------------------
local function apply_color(r, g, b)
  local bgr = rgb_to_bgr_int(r, g, b)
  reaper.Undo_BeginBlock()

  if apply_to_items then
    local items = {}
    local itemCount = reaper.CountSelectedMediaItems(0)

    -- Stocker les pointeurs des items sélectionnés
    for i = 0, itemCount - 1 do
      local item = reaper.GetSelectedMediaItem(0, i)
      if item then table.insert(items, item) end
    end

    -- Appliquer la couleur aux items
    for _, item in ipairs(items) do
      reaper.SetMediaItemInfo_Value(item, 'I_CUSTOMCOLOR', bgr)
    end

    -- === Colorer la piste correspondant à l'item si dans "TRACKS" ===
    local guideTrack = FindTracksGuide()
    if guideTrack then
      for _, item in ipairs(items) do
        local itemTrack = reaper.GetMediaItem_Track(item)
        if itemTrack == guideTrack then
          local take = reaper.GetActiveTake(item)
          if take then
            local _, takeName = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)
            local strippedTakeName = StripPrefix(takeName)

            -- Chercher la piste correspondante
            local trackCount = reaper.CountTracks(0)
            for i = 0, trackCount - 1 do
              local track = reaper.GetTrack(0, i)
              local _, trackName = reaper.GetTrackName(track)
              if StripPrefix(trackName) == strippedTakeName then
                -- Appliquer la couleur à la piste correspondante
                reaper.SetMediaTrackInfo_Value(track, 'I_CUSTOMCOLOR', bgr)

                -- Désélectionner la piste "TRACKS" si sélectionnée
                if reaper.IsTrackSelected(guideTrack) then
                  reaper.SetTrackSelected(guideTrack, false)
                end

                -- Sélectionner uniquement la piste cible
                reaper.SetOnlyTrackSelected(track)
                break
              end
            end
          end
        end
      end
    end
    for _, item in ipairs(items) do
      if item then
        reaper.SetMediaItemSelected(item, false)
      end
    end
    createitemsfromtracks()
  end

  if apply_to_tracks then
    for i = 0, reaper.CountSelectedTracks(0)-1 do
      local track = reaper.GetSelectedTrack(0, i)
      reaper.SetMediaTrackInfo_Value(track, 'I_CUSTOMCOLOR', bgr)
    end
    createitemsfromtracks()
  end

  reaper.Undo_EndBlock('Apply color', -1)
  reaper.UpdateArrange()
end

----- TO ZOOM TRACK
---1 Select all except first
function SelAllExceptFirst()
    reaper.Main_OnCommand(40297, 0) -- Unselect all tracks
    local track_count = reaper.CountTracks(0)
    for i = 1, track_count - 1 do
        local track = reaper.GetTrack(0, i)
        reaper.SetTrackSelected(track, true)
    end
    reaper.UpdateArrange()
end
--2 ZOOM SELECTED
function ZoomToItemsOnSelectedTracks()
    -- Vérifie s'il y a des pistes sélectionnées
    local num_selected_tracks = reaper.CountSelectedTracks(0)
    if num_selected_tracks == 0 then
        reaper.ShowMessageBox("Aucune piste sélectionnée.", "Erreur", 0)
        return
    end

    -- Désélectionner tous les items d'abord
    reaper.Main_OnCommand(40289, 0) -- Unselect all items

    local total_items_selected = 0

    -- Parcours de toutes les pistes sélectionnées
    for i = 0, num_selected_tracks - 1 do
        local track = reaper.GetSelectedTrack(0, i)
        local item_count = reaper.CountTrackMediaItems(track)

        for j = 0, item_count - 1 do
            local item = reaper.GetTrackMediaItem(track, j)
            reaper.SetMediaItemSelected(item, true)
            total_items_selected = total_items_selected + 1
        end
    end

    if total_items_selected == 0 then
        reaper.ShowMessageBox("Aucun item trouvé sur les pistes sélectionnées.", "Info", 0)
        return
    end

    -- Zoom horizontal sur les items sélectionnés
    reaper.Main_OnCommand(40913, 0) -- View: Zoom to selected items
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_SAFETIMESEL"), 0)
    reaper.Main_OnCommand(40031,0)
    reaper.Main_OnCommand(40635,0)
    reaper.Main_OnCommand(40289,0)
end
------------------------------------ START ABC --------------------------------------------------------------
-- Tri alphabétique des pistes sélectionnées avec bascule automatique A↔Z
-- Premier appel → A→Z, second → Z→A, etc.

-- Variable persistante pour retenir le sens du dernier tri
local lastDescending = false

local function AlphabeticalSortSelectedTracksToggle()
  reaper.Main_OnCommand(40026, 0) -- Sauvegarde du projet
  -- Inverser le sens du tri à chaque appel
  lastDescending = not lastDescending

  local selNum = reaper.CountSelectedTracks(0)
  if selNum == 0 then return end

  reaper.Undo_BeginBlock2(0)
  reaper.PreventUIRefresh(1)

  -- Collecte des pistes sélectionnées
  local tracks = {}
  for i = 1, selNum do
    local tr = reaper.GetSelectedTrack(0, i - 1)
    local _, name = reaper.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
    tracks[#tracks + 1] = { track = tr, name = name or "" }
  end

  -- Trouver la position de la piste juste au-dessus du bloc sélectionné
  local trackAboveIdx = reaper.GetMediaTrackInfo_Value(tracks[1].track, "IP_TRACKNUMBER") - 1

  -- Tri alphabétique (insensible à la casse)
  table.sort(tracks, function(a, b)
    local aName, bName = string.upper(a.name), string.upper(b.name)
    if lastDescending then
      return aName > bName
    else
      return aName < bName
    end
  end)

  -- Désélectionner toutes les pistes
  for _, t in ipairs(tracks) do
    reaper.SetTrackSelected(t.track, false)
  end

  -- Réorganisation des pistes
  for _, t in ipairs(tracks) do
    reaper.SetTrackSelected(t.track, true)
    reaper.ReorderSelectedTracks(trackAboveIdx, 0)
    reaper.SetTrackSelected(t.track, false)
  end

  -- Restaurer la sélection
  for _, t in ipairs(tracks) do
    reaper.SetTrackSelected(t.track, true)
  end

  reaper.PreventUIRefresh(-1)

  local direction = lastDescending and "Z→A" or "A→Z"
  reaper.Undo_EndBlock2(0, "Sort selected tracks alphabetically (" .. direction .. ")", -1)
end



---------------------- end ABC ------------------------------------------------------------------
---------------------------------
local function toggleTracksGuideVisibility(visible)
  local guideTrack = FindTracksGuide()
  if not guideTrack then return end

  -- 0 = invisible, 1 = visible
  local tcp_val = visible and 1 or 0
  local mcp_val = visible and 1 or 0

  reaper.SetMediaTrackInfo_Value(guideTrack, "B_SHOWINTCP", tcp_val)
  reaper.SetMediaTrackInfo_Value(guideTrack, "B_SHOWINMIXER", mcp_val)

  reaper.TrackList_AdjustWindows(false)
end

------------------------------------------------------------

local function SelectTrackFromItem()
  local guideTrack = FindTracksGuide()
  if not guideTrack then
    reaper.ShowMessageBox("La piste 'TRACKS' est introuvable.", "Erreur", 0)
    return false
  end

  local selectedItem = reaper.GetSelectedMediaItem(0, 0)
  if not selectedItem then
    reaper.ShowMessageBox("Aucun item sélectionné.", "Info", 0)
    return false
  end

  local itemTrack = reaper.GetMediaItem_Track(selectedItem)
  if itemTrack ~= guideTrack then
    reaper.ShowMessageBox("L'item sélectionné n'est pas dans la piste 'TRACKS'.", "Info", 0)
    return false
  end

  local take = reaper.GetActiveTake(selectedItem)
  if not take then
    reaper.ShowMessageBox("L'item sélectionné n'a pas de take actif.", "Info", 0)
    return false
  end

  local _, takeName = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)
  local strippedTakeName = StripPrefix(takeName)

  local trackCount = reaper.CountTracks(0)
  for i = 0, trackCount - 1 do
    local track = reaper.GetTrack(0, i)
    local _, trackName = reaper.GetTrackName(track)
    if StripPrefix(trackName) == strippedTakeName then
      reaper.SetOnlyTrackSelected(track)
      reaper.Main_OnCommand(40913, 0) -- Centrer la vue sur la piste sélectionnée
      return true
    end
  end

  reaper.ShowMessageBox("Aucune piste correspondant au nom '"..strippedTakeName.."' trouvée.", "Info", 0)
  return false
end

------------------------------------------------------------
-----Fonction VIEW ALL
local zoomedOnTrackItems = false  -- variable mémoire temporaire

local function viewall()
  local guideTrack = FindTracksGuide()
  if not guideTrack then return end

  local swsZoomCmdID = reaper.NamedCommandLookup("_SWS_HZOOMITEMS") -- commande SWS zoom horizontal sur items sélectionnés
  

  if not zoomedOnTrackItems then
    reaper.Main_OnCommand(40289, 0) -- Unselect all items
    local itemCount = reaper.CountTrackMediaItems(guideTrack)
    if itemCount == 0 then return end
    for i = 0, itemCount - 1 do
      local item = reaper.GetTrackMediaItem(guideTrack, i)
      reaper.SetMediaItemSelected(item, true)
    end
    if swsZoomCmdID ~= 0 then
      reaper.Main_OnCommand(swsZoomCmdID, 0)
      reaper.Main_OnCommand(40289, 0)
    else
      reaper.ShowMessageBox("Commande SWS _SWS_HZOOMITEMS introuvable", "Erreur", 0)
    end
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_UNSELONTRACKS"), 0)
    zoomedOnTrackItems = true
  else
   SelAllExceptFirst()
   ZoomToItemsOnSelectedTracks()
    zoomedOnTrackItems = false
  end
  reaper.UpdateArrange()
end

------------------------------------------------------------
function createitemsfromtracks()
  local reaper = reaper
---------------------------------
  local function MoveSelectedTrackToTop()
    local track = reaper.GetSelectedTrack(0, 0)
    if not track then return end
    reaper.SetOnlyTrackSelected(track)
    reaper.ReorderSelectedTracks(0, 0)
  end
---------------------------------
  local function SetOnlyTrackSelected(track)
    reaper.Main_OnCommand(40297, 0) -- Unselect all tracks
    reaper.SetTrackSelected(track, true)
  end
---------------------------------
  local function AddTakeMarkerSafe(take, pos, name, color)
    if take then
      reaper.SetTakeMarker(take, -1, name or "", pos or 0, color or 0)
    end
  end
---------------------------------
  local function GetOrCreateTracksGuide()
    local trackCount = reaper.CountTracks(0)
    for i = 0, trackCount - 1 do
      local tr = reaper.GetTrack(0, i)
      local _, name = reaper.GetTrackName(tr)
      if name == "TRACKS" then
        -- Supprimer les items existants
        local itemCount = reaper.CountTrackMediaItems(tr)
        for j = itemCount - 1, 0, -1 do
          local item = reaper.GetTrackMediaItem(tr, j)
          reaper.DeleteTrackMediaItem(tr, item)
        end
        local white = rgb_to_bgr_int(1, 1, 1)
        reaper.SetMediaTrackInfo_Value(tr, "I_CUSTOMCOLOR", white | 0x1000000)
        return tr
      end
    end
    reaper.InsertTrackAtIndex(trackCount, true)
    local tr = reaper.GetTrack(0, trackCount)
    reaper.SetOnlyTrackSelected(tr) -- Nécessaire pour que la commande s'applique
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_SELTRAXHEIGHTB"), 0)
    reaper.GetSetMediaTrackInfo_String(tr, "P_NAME", "TRACKS", true)
    reaper.Main_OnCommand(41312,0)
    local white = rgb_to_bgr_int(1, 1, 1)
    reaper.SetMediaTrackInfo_Value(tr, "I_CUSTOMCOLOR", white | 0x1000000)
    return tr
  end
---------------------------------
  local function CreateTrackItem(track, startPos, length, name, color, fxList)
    local item = reaper.AddMediaItemToTrack(track)
    reaper.SetMediaItemInfo_Value(item, "D_POSITION", startPos)
    reaper.SetMediaItemInfo_Value(item, "D_LENGTH", length)
    reaper.SetMediaItemInfo_Value(item, "B_LOOPSRC", 0)
    if color and color ~= 0 then
      reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", color | 0x1000000)
    else
      reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", 0) -- noir pour les spacers
    end
    local take = reaper.AddTakeToMediaItem(item)
    if take and name then
      reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", name, true)
    end
    if take and fxList then
      for _, fxName in ipairs(fxList) do
        AddTakeMarkerSafe(take, 0, fxName, 0)
      end
    end
    return item
  end

  -- MAIN
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)

  local guideTrack = GetOrCreateTracksGuide()
  local pos = 0
  local trackCount = reaper.CountTracks(0)
  local num = 1

  for i = 0, trackCount - 1 do
    local tr = reaper.GetTrack(0, i)
    local _, name = reaper.GetTrackName(tr)
    local color = reaper.GetMediaTrackInfo_Value(tr, "I_CUSTOMCOLOR")

    -- Collecter les FX de la piste
    local fxList = {}
    local fxCount = reaper.TrackFX_GetCount(tr)
    for fx = 0, fxCount - 1 do
      local retval, fxName = reaper.TrackFX_GetFXName(tr, fx, "")
      if retval and fxName ~= "" then table.insert(fxList, fxName) end
    end
    local itemName = string.format("%02d - %s", num, name)
    CreateTrackItem(guideTrack, pos, 10, itemName, color, fxList)
    pos = pos + 10
    num = num + 1
    local nextTrack = reaper.GetTrack(0, i + 1)
    if nextTrack then
      local spacerNext = reaper.GetMediaTrackInfo_Value(nextTrack, "I_SPACER")
      if spacerNext ~= 0 then
        CreateTrackItem(guideTrack, pos, 1, "SPACER", 0, nil)
        pos = pos + 1
      end
    end
  end
---------------------------------
  SetOnlyTrackSelected(guideTrack)
  -- Pinner la piste TRACKS tout en haut
    reaper.Main_OnCommand(40008, 0) -- Pin track to top only if not already pinned
---------------------------------
--  MoveSelectedTrackToTop()
--  local DelRegions = reaper.NamedCommandLookup("_SWSMARKERLIST10")
  --local ItemsToRegions = reaper.NamedCommandLookup("_SWS_REGIONSFROMITEMS")

 -- reaper.Main_OnCommand(40421, 0) -- Select all items
  --reaper.Main_OnCommand(DelRegions, 0)
  --reaper.Main_OnCommand(ItemsToRegions, 0)
--reaper.Main_OnCommand(40289, 0) -- Unselect all items
--reaper.PreventUIRefresh(-1)
--reaper.UpdateArrange()
--reaper.Undo_EndBlock("Représentation des pistes sur TRACKS avec spacers noirs", -1)
end
------------------------------------------------------------
-- fonction add Track
------------------------------------------------------------
local function addtrack()
  ---------------------------------
  local guideTrack = FindTracksGuide()
  local selectedItem = reaper.GetSelectedMediaItem(0, 0)
  if selectedItem and guideTrack then
    local itemTrack = reaper.GetMediaItem_Track(selectedItem)
    if itemTrack == guideTrack then
      SelectTrackFromItem()
    end
  end
  ---------------------------------

  local sel_track = reaper.GetSelectedTrack(0, 0)
  if not sel_track then
    reaper.ShowMessageBox("Aucune piste sélectionnée.", "Erreur", 0)
    return
  end

  -- Fonction : vérifier si un nom de piste existe déjà
  local function TrackNameExists(name)
    local trackCount = reaper.CountTracks(0)
    for i = 0, trackCount - 1 do
      local tr = reaper.GetTrack(0, i)
      local _, trName = reaper.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
      if trName == name then
        return true
      end
    end
    return false
  end

  -- Fonction : demander un nom à l’utilisateur (avec vérification de doublon)
  local function AskForUniqueTrackName(defaultName)
    local user_input = defaultName or ""
    while true do
      local retval, input = reaper.GetUserInputs("Nom de la nouvelle piste", 1, "Nom de la piste:", user_input)
      if not retval or input == "" then
        return nil -- annulation
      end

      if not TrackNameExists(input) then
        return input
      else
        local res = reaper.ShowMessageBox(
          "Une piste nommée \"" .. input .. "\" existe déjà.\n\nVeuillez entrer un autre nom.",
          "Nom déjà utilisé",
          0
        )
        user_input = input -- préremplir la prochaine saisie
      end
    end
  end

  -- Demande du nom unique à l'utilisateur
  local user_input = AskForUniqueTrackName("")
  if not user_input then
    reaper.ShowMessageBox("Création de piste annulée.", "Info", 0)
    return
  end

  local sel_index = reaper.GetMediaTrackInfo_Value(sel_track, "IP_TRACKNUMBER") -- index + 1
  local insert_index = math.floor(sel_index) -- position où insérer

  reaper.Undo_BeginBlock()

  reaper.InsertTrackAtIndex(insert_index, true)
  local new_track = reaper.GetTrack(0, insert_index)

  reaper.GetSetMediaTrackInfo_String(new_track, 'P_NAME', user_input, true)
  reaper.SetOnlyTrackSelected(new_track)

  -- Couleur par défaut (gris clair)
  local default_color = rgb_to_bgr_int(0.8, 0.8, 0.8)
  reaper.SetMediaTrackInfo_Value(new_track, "I_CUSTOMCOLOR", default_color | 0x1000000)

  createitemsfromtracks()

  reaper.Undo_EndBlock("Ajouter une piste nommée après la sélection (nom unique)", -1)
end
-------------------
-- fonction delete Track
------------------------------------------------------------
local function deltrack()
  local sel_track = reaper.GetSelectedTrack(0, 0)
  if not sel_track then
    reaper.ShowMessageBox("Aucune piste sélectionnée.", "Erreur", 0)
    return
  end

  reaper.Undo_BeginBlock()

  -- Supprimer la piste sélectionnée
  reaper.DeleteTrack(sel_track)

  -- Synchroniser les pistes avec la guide track
  createitemsfromtracks()

  reaper.Undo_EndBlock("Supprimer la piste sélectionnée et synchroniser", -1)
end


------------------------------------------------------------
--Fonction addspacer()
local function addspacer()
  local sel_track = reaper.GetSelectedTrack(0, 0)
  if not sel_track then
    reaper.ShowMessageBox("Aucune piste sélectionnée.", "Erreur", 0)
    return
  end

  reaper.Undo_BeginBlock()

  reaper.Main_OnCommand(42666, 0) -- Insert Visual Spacer (native command)

  createitemsfromtracks()

  reaper.Undo_EndBlock("Ajouter un spacer après la piste sélectionnée", -1)
end
---------------------------------
--Fonction delspacer()
local function delspacer()
  local sel_track = reaper.GetSelectedTrack(0, 0)
  if not sel_track then
    reaper.ShowMessageBox("Aucune piste sélectionnée.", "Erreur", 0)
    return
  end

  reaper.Undo_BeginBlock()

  reaper.Main_OnCommand(42668, 0) -- remove Visual Spacer (native command)

  createitemsfromtracks()

  reaper.Undo_EndBlock("Ajouter un spacer après la piste sélectionnée", -1)
end

---------------------------------------------------------
local function FindTracksGuide2()
  local trackCount = reaper.CountTracks(0)
  for i = 0, trackCount - 1 do
    local tr = reaper.GetTrack(0, i)
    local _, name = reaper.GetTrackName(tr)
    if name == "TRACKS" then
      return tr
    end
  end
  return nil
end

------------------------------------------
-- LOGIQUE DE SÉLECTION
local function SelectTrackFromItem()
  local guideTrack = FindTracksGuide2()
  if not guideTrack then return false end

  local selectedItem = reaper.GetSelectedMediaItem(0, 0)
  if not selectedItem then return false end

  local itemTrack = reaper.GetMediaItem_Track(selectedItem)
  if itemTrack ~= guideTrack then return false end

  local take = reaper.GetActiveTake(selectedItem)
  if not take then return false end

  local _, takeName = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)
  local strippedTakeName = StripPrefix(takeName)

  local trackCount = reaper.CountTracks(0)
  for i = 0, trackCount - 1 do
    local track = reaper.GetTrack(0, i)
    local _, trackName = reaper.GetTrackName(track)
    if StripPrefix(trackName) == strippedTakeName then
      reaper.SetOnlyTrackSelected(track)
      return true
    end
  end

  return false
end
---------------------------------
local function SelectItemFromTrack()
  local guideTrack = FindTracksGuide2()
  if not guideTrack then return false end

  local selectedTrack = reaper.GetSelectedTrack(0, 0)
  if not selectedTrack or selectedTrack == guideTrack then return false end

  local _, selectedTrackName = reaper.GetTrackName(selectedTrack)
  local strippedTrackName = StripPrefix(selectedTrackName)

  local itemCount = reaper.CountTrackMediaItems(guideTrack)
  for i = 0, itemCount - 1 do
    local item = reaper.GetTrackMediaItem(guideTrack, i)
    local take = reaper.GetActiveTake(item)
    if take then
      local _, takeName = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)
      if StripPrefix(takeName) == strippedTrackName then
        reaper.Main_OnCommand(40289, 0) -- Unselect all items
        reaper.SetMediaItemSelected(item, true)
        reaper.UpdateArrange()
        return true
      end
    end
  end

  return false
end
---------------------------------
local function MirrorSelection()
  if SelectTrackFromItem() then
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_RESTOREVIEW"), 0)--- restore valeur de Zoom sauvé lors du focus Item
    -- On a sélectionné la piste, on centre sur la piste (vue arrange)
    reaper.Main_OnCommand(40913, 0) -- Zoom sur sélection (piste)
    return
    reaper.Main_OnCommand(40289,0) --- unselect ALL Items
  end

  if SelectItemFromTrack() then
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_SAVEVIEW"), 0) ---- sauve la valeur de Zoom pour FOCUSING
    -- On a sélectionné l'item dans TRACKS, zoom horizontal SWS sur l'item
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_HZOOMITEMS"), 0)
    reaper.Main_OnCommand(1011,0)
    reaper.Main_OnCommand(1011,0)
    reaper.Main_OnCommand(1011,0)
    reaper.Main_OnCommand(1011,0)
    reaper.Main_OnCommand(1011,0)
    reaper.Main_OnCommand(1011,0)
    reaper.Main_OnCommand(1011,0)
    reaper.Main_OnCommand(40939,0)
    end
end

---------------------------------
local function GetSelectionStatus()
  local selectedItem = reaper.GetSelectedMediaItem(0, 0)
  local itemName = "(aucun)"
  if selectedItem then
    local take = reaper.GetActiveTake(selectedItem)
    if take then
      local _, name = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)
      itemName = name
    end
  end

  local selectedTrack = reaper.GetSelectedTrack(0, 0)
  local trackName = "(aucune)"
  if selectedTrack then
    local _, name = reaper.GetTrackName(selectedTrack)
    trackName = name
  end

  return itemName, trackName
end

-------------------------------------------------------------------------------

---------------------CreateTRACKSfromITEMS------------------------

-------------------------------------------------------------------------------
-- Fonction principale que tu appelleras depuis ton autre script
function createTracksFromItems()

  local function CreateSpacerTrack()
    local idx = reaper.CountTracks(0)
    reaper.InsertTrackAtIndex(idx, true)
    local tr = reaper.GetTrack(0, idx)
    reaper.SetMediaTrackInfo_Value(tr, "I_SPACER", 1)
    return tr
  end

  local function CreateStandardTrack(name, color, fxList)
    local idx = reaper.CountTracks(0)
    reaper.InsertTrackAtIndex(idx, true)
    local tr = reaper.GetTrack(0, idx)
    reaper.GetSetMediaTrackInfo_String(tr, "P_NAME", name, true)

    if color and color ~= 0 then
      reaper.SetMediaTrackInfo_Value(tr, "I_CUSTOMCOLOR", color)
    end

    if fxList then
      for _, fxName in ipairs(fxList) do
        local fxIdx = reaper.TrackFX_AddByName(tr, fxName, false, -1)
        if fxIdx == -1 then
          reaper.ShowConsoleMsg("⚠️ FX non trouvé : " .. fxName .. "\n")
        end
      end
    end

    return tr
  end
---------------------------------
  local function DeleteAllTracksExceptGuide()
    local guideTrack = nil
    local trackCount = reaper.CountTracks(0)
    for i = trackCount - 1, 0, -1 do
      local tr = reaper.GetTrack(0, i)
      local _, name = reaper.GetTrackName(tr)
      if name == "TRACKS" then
        guideTrack = tr
      else
        reaper.DeleteTrack(tr)
      end
    end
    return guideTrack
  end
---------------------------------
  local function TrackNameExists(nameToCheck)
    local count = reaper.CountTracks(0)
    for i = 0, count - 1 do
      local tr = reaper.GetTrack(0, i)
      local _, name = reaper.GetTrackName(tr)
      if name == nameToCheck then
        return true
      end
    end
    return false
  end
---------------------------------
  local function GetTakeFXMarkers(take)
    local fxList = {}
    local markerCount = reaper.GetNumTakeMarkers(take)
    for i = 0, markerCount - 1 do
      local _, name = reaper.GetTakeMarker(take, i)
      if name and name ~= "" then
        table.insert(fxList, name)
      end
    end
    return fxList
  end
---------------------------------
  local function SelectSpacerTracks()
    reaper.Main_OnCommand(40297, 0) -- Unselect all tracks
    local count = reaper.CountTracks(0)
    for i = 0, count - 1 do
      local tr = reaper.GetTrack(0, i)
      local isSpacer = reaper.GetMediaTrackInfo_Value(tr, "I_SPACER")
      if isSpacer and isSpacer ~= 0 then
        reaper.SetTrackSelected(tr, true)
      end
    end
  end
---------------------------------
  -- MAIN LOGIC
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)

  local guideTrack = DeleteAllTracksExceptGuide()
  if not guideTrack then
    reaper.MB("❌ Piste 'TRACKS' introuvable.", "Erreur", 0)
    reaper.PreventUIRefresh(-1)
    return
  end

  local itemCount = reaper.CountTrackMediaItems(guideTrack)

  for i = 0, itemCount - 1 do
    local item = reaper.GetTrackMediaItem(guideTrack, i)
    local take = reaper.GetActiveTake(item)

    if take then
      local _, rawName = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)
      rawName = rawName or ""

      if rawName == "SPACER" then
        CreateSpacerTrack()
      else
        local name = rawName:match("^%d+%s*%-*%s*(.+)$") or rawName
        if not TrackNameExists(name) then
          local color = reaper.GetMediaItemInfo_Value(item, "I_CUSTOMCOLOR")
          local fxList = GetTakeFXMarkers(take)
          CreateStandardTrack(name, color, fxList)
        end
      end
    end
  end
---------------------------------
  SelectSpacerTracks()
  reaper.Main_OnCommand(40697, 0) -- Unselect all items

  local countSelTracks = reaper.CountSelectedTracks(0)
  if countSelTracks > 0 then
    reaper.Main_OnCommand(40337, 0) -- Folder compact if any
  end
  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
  reaper.Undo_EndBlock("Reconstruire pistes depuis 'TRACKS'", -1)
  createitemsfromtracks()
end

--------
--------
--------
---------------------------------



local function ReorderTracksByItems()
    local ctx = reaper.ImGui_CreateContext('Reorder Tracks by Items')
    local font = reaper.ImGui_CreateFont('sans-serif', 16)
    reaper.ImGui_Attach(ctx, font)

    ------------------------------------------
    -- Helpers internes
    ------------------------------------------
    local function RemoveAllSpacers()
        reaper.Main_OnCommand(40297, 0)
        local count = reaper.CountTracks(0)
        for i = 0, count - 1 do
            local tr = reaper.GetTrack(0, i)
            reaper.SetTrackSelected(tr, true)
        end
        reaper.Main_OnCommand(42670, 0)
    end

    local function CreateSpacerAt(index)
        local trackCount = reaper.CountTracks(0)
        if index > trackCount then index = trackCount end
        reaper.InsertTrackAtIndex(index, true)
        local tr = reaper.GetTrack(0, index)
        reaper.SetMediaTrackInfo_Value(tr, "I_SPACER", 1)
    end

    local function MoveTracksByItem()
        reaper.Undo_BeginBlock()
        reaper.PreventUIRefresh(1)

        -- Recherche la piste "TRACKS"
        local trackCount = reaper.CountTracks(0)
        local trackRef = nil
        for i = 0, trackCount - 1 do
            local tr = reaper.GetTrack(0, i)
            local _, name = reaper.GetTrackName(tr, "")
            if name == "TRACKS" then
                trackRef = tr
                break
            end
        end

        if not trackRef then
            reaper.ShowMessageBox("No track named 'TRACKS' found.", "Error", 0)
            reaper.PreventUIRefresh(-1)
            return
        end

        local itemCount = reaper.CountTrackMediaItems(trackRef)
        if itemCount == 0 then
            reaper.ShowMessageBox("No items found on 'TRACKS' track.", "Info", 0)
            reaper.PreventUIRefresh(-1)
            return
        end

        RemoveAllSpacers()

        local trackItems = {}
        for i = 0, itemCount - 1 do
            local item = reaper.GetTrackMediaItem(trackRef, i)
            local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
            local _, itemName = reaper.GetSetMediaItemTakeInfo_String(reaper.GetActiveTake(item), "P_NAME", "", false)

            if itemName and itemName ~= "" then
                if itemName == "SPACER" then
                    table.insert(trackItems, {name = "SPACER", pos = pos})
                else
                    local _, _, trackName = string.find(itemName, "^[%d%s]*%-[%s]*(.+)")
                    if trackName then
                        table.insert(trackItems, {name = trackName, pos = pos})
                    end
                end
            end
        end

        table.sort(trackItems, function(a, b) return a.pos < b.pos end)

        local currentIndex = 0
        for _, data in ipairs(trackItems) do
            if data.name == "SPACER" then
                CreateSpacerAt(currentIndex)
                currentIndex = currentIndex + 1
            else
                for j = 0, reaper.CountTracks(0) - 1 do
                    local tr = reaper.GetTrack(0, j)
                    local _, trName = reaper.GetTrackName(tr, "")
                    if trName == data.name then
                        reaper.SetOnlyTrackSelected(tr)
                        reaper.ReorderSelectedTracks(currentIndex, 0)
                        currentIndex = currentIndex + 1
                        break
                    end
                end
            end
        end

        reaper.Main_OnCommand(40297, 0)
        reaper.UpdateArrange()
        reaper.PreventUIRefresh(-1)
        reaper.Undo_EndBlock("Reorder tracks by items on TRACKS (with spacers)", -1)

        -- Sélection des pistes sans nom
        reaper.Undo_BeginBlock()
        reaper.Main_OnCommand(40297, 0)

        local track_count = reaper.CountTracks(0)
        for i = 0, track_count - 1 do
            local track = reaper.GetTrack(0, i)
            local _, name = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
            if name == "" then
                reaper.SetTrackSelected(track, true)
            end
        end

      reaper.Undo_EndBlock("Select Tracks without name", -1)

      -- ✅ Évite le popup "No tracks selected"
      local sel_count = reaper.CountSelectedTracks(0)
      if sel_count > 0 then
      reaper.Main_OnCommand(40337, 0)
      end

      createitemsfromtracks()

    end

    -------------------------------------------------------------
    -- GUI 
    -------------------------------------------------------------
    local function Main()
        reaper.ImGui_PushFont(ctx, font, 16)
        reaper.ImGui_SetNextWindowSize(ctx, 800, 70, reaper.ImGui_Cond_FirstUseEver())

                         
        local visible, open = reaper.ImGui_Begin(ctx, 'Reorder Tracks', true)

        if visible then
            reaper.ImGui_Text(ctx, "Reorder project tracks based on items on 'TRACKS'")
            reaper.ImGui_Text(ctx, "Items named 'SPACER' → visual spacers created.")
            reaper.ImGui_Separator(ctx)
            reaper.ImGui_Dummy(ctx, 0, 10)

            if reaper.ImGui_Button(ctx, "Reorder Tracks by Items", 280, 40) then
                MoveTracksByItem()
            end

            reaper.ImGui_End(ctx)
        end

        reaper.ImGui_PopFont(ctx)

        if open then
            reaper.defer(Main)
        end
    end

    MoveTracksByItem()
end



--------------------------------------------------------------------------------------------------------
----------------------------------- MOVE ITEMS FORWARD AND BACKWARD ------------------------------------

-->>>>>> MoveItemForward.lua
function MoveItemForward()
  local sel_item = reaper.GetSelectedMediaItem(0, 0)
  if not sel_item or reaper.CountSelectedMediaItems(0) ~= 1 then
    reaper.MB("Sélectionne un seul item pour le déplacer.", "Erreur", 0)
    return
  end

  local track = reaper.GetMediaItemTrack(sel_item)
  local item_pos = reaper.GetMediaItemInfo_Value(sel_item, "D_POSITION")
  local item_end = item_pos + reaper.GetMediaItemInfo_Value(sel_item, "D_LENGTH")

  local item_count = reaper.CountTrackMediaItems(track)
  local next_item = nil
  local next_item_pos = math.huge

  for i = 0, item_count - 1 do
    local item = reaper.GetTrackMediaItem(track, i)
    if item ~= sel_item then
      local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
      if pos >= item_end and pos < next_item_pos then
        next_item = item
        next_item_pos = pos
      end
    end
  end

  if not next_item then
    reaper.MB("Aucun item suivant trouvé sur cette piste.", "Info", 0)
    return
  end

  local sel_pos = reaper.GetMediaItemInfo_Value(sel_item, "D_POSITION")
  local next_pos = reaper.GetMediaItemInfo_Value(next_item, "D_POSITION")

  reaper.Undo_BeginBlock()
  reaper.SetMediaItemInfo_Value(sel_item, "D_POSITION", next_pos)
  reaper.SetMediaItemInfo_Value(next_item, "D_POSITION", sel_pos)

  reaper.SetMediaItemSelected(sel_item, true)
  reaper.SetMediaItemSelected(next_item, false)

  reaper.UpdateArrange()
  reaper.Undo_EndBlock("Pousser l'item sélectionné vers l’avant (swap)", -1)
  reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_HZOOMITEMS"), 0)
  reaper.Main_OnCommand(1011,0)
  reaper.Main_OnCommand(1011,0)
  reaper.Main_OnCommand(1011,0)
  reaper.Main_OnCommand(1011,0)
  reaper.Main_OnCommand(1011,0)
  reaper.Main_OnCommand(1011,0)
  reaper.Main_OnCommand(1011,0)
  reaper.Main_OnCommand(1011,0)
end

---------------------------------
function MoveItemBackward()
  local sel_item = reaper.GetSelectedMediaItem(0, 0)
  if not sel_item or reaper.CountSelectedMediaItems(0) ~= 1 then
    reaper.MB("Sélectionne un seul item pour le déplacer.", "Erreur", 0)
    return
  end

  local track = reaper.GetMediaItemTrack(sel_item)
  local item_pos = reaper.GetMediaItemInfo_Value(sel_item, "D_POSITION")

  local item_count = reaper.CountTrackMediaItems(track)
  local prev_item = nil
  local prev_item_pos = -math.huge

  for i = 0, item_count - 1 do
    local item = reaper.GetTrackMediaItem(track, i)
    if item ~= sel_item then
      local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
      if pos < item_pos and pos > prev_item_pos then
        prev_item = item
        prev_item_pos = pos
      end
    end
  end

  if not prev_item then
    reaper.MB("Aucun item précédent trouvé sur cette piste.", "Info", 0)
    return
  end

  local sel_pos = reaper.GetMediaItemInfo_Value(sel_item, "D_POSITION")
  local prev_pos = reaper.GetMediaItemInfo_Value(prev_item, "D_POSITION")

  reaper.Undo_BeginBlock()
  reaper.SetMediaItemInfo_Value(sel_item, "D_POSITION", prev_pos)
  reaper.SetMediaItemInfo_Value(prev_item, "D_POSITION", sel_pos)

  -- Garde sélectionné l’item déplacé (toujours sel_item)
  reaper.SetMediaItemSelected(sel_item, true)
  reaper.SetMediaItemSelected(prev_item, false)

  reaper.UpdateArrange()
  reaper.Undo_EndBlock("Pousser l'item sélectionné vers l’arrière (swap)", -1)
  reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_HZOOMITEMS"), 0)
  reaper.Main_OnCommand(1011,0)
  reaper.Main_OnCommand(1011,0)
  reaper.Main_OnCommand(1011,0)
  reaper.Main_OnCommand(1011,0)
  reaper.Main_OnCommand(1011,0)
  reaper.Main_OnCommand(1011,0)
  reaper.Main_OnCommand(1011,0)
  reaper.Main_OnCommand(1011,0)
end

-------------------------------- F I N D -------------------------------------
------------------------------------------------------------------------------
local function FindTracksGuide()
  for i = 0, reaper.CountTracks(0) - 1 do
    local tr = reaper.GetTrack(0, i)
    local _, name = reaper.GetTrackName(tr)
    if name == "TRACKS" then return tr end
  end
  return nil
end
---------------------------------
local function SearchItemsInTracks(text)
  search_results = {}
  local guideTrack = FindTracksGuide()
  if not guideTrack or text == "" then return end

  local itemCount = reaper.CountTrackMediaItems(guideTrack)
  for i = 0, itemCount - 1 do
    local item = reaper.GetTrackMediaItem(guideTrack, i)
    local take = reaper.GetActiveTake(item)
    if take then
      local _, takeName = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)
      if takeName:lower():find(text:lower()) then
        table.insert(search_results, { name = takeName, item = item })
      end
    end
  end
end
---------------------------------
function DrawTracksSearchWindow()
  local visible
  visible, show_tracks_search = reaper.ImGui_Begin(ctx, "Recherche dans TRACKS", show_tracks_search, reaper.ImGui_WindowFlags_AlwaysAutoResize())

  if visible then
    reaper.ImGui_Text(ctx, "🔍 Recherche dans les items de la piste 'TRACKS'")
    reaper.ImGui_Text(ctx, "Appuyer sur Return pour rechercher")

    local enter_pressed
    enter_pressed, search_text = reaper.ImGui_InputText(ctx, "##search", search_text, reaper.ImGui_InputTextFlags_EnterReturnsTrue())

    if enter_pressed then
      SearchItemsInTracks(search_text)
    end

    reaper.ImGui_Separator(ctx)

    for i, result in ipairs(search_results) do
      if reaper.ImGui_Selectable(ctx, result.name) then
        reaper.Main_OnCommand(40289, 0) -- Unselect all items
        reaper.SetMediaItemSelected(result.item, true)
        reaper.Main_OnCommand(40913, 0) -- Zoom sur l’item sélectionné
        reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_HZOOMITEMS"), 0)
        reaper.Main_OnCommand(1011, 0)
        reaper.Main_OnCommand(1011, 0)
        reaper.Main_OnCommand(1011, 0)
        reaper.Main_OnCommand(1011, 0)
        reaper.Main_OnCommand(1011, 0)
        reaper.UpdateArrange()
        show_tracks_search = false -- fermeture automatique
      end
    end

    reaper.ImGui_End(ctx)
  end
end

-------------------------------------------------------------------------------------------------------
------------------------------- FIND2 -----------------------------------------------------------------
function RechercheItemsGUI(ctx)
  -- Variables locales internes
  local open = true
  local search_text = ''
  local search_results = {}
  local search_results_tkm = {}
  local select_multiple = false
  local selected_mode = 0

  local search_modes = {
    "Nom du Take",
    "Nom de la Piste",
    "Items Mutés",
    "Take Markers"
  }
---------------------------------
  local function SearchProjectItems(text, mode)
    search_results = {}
    search_results_tkm = {}
    if text == "" and mode ~= 2 then return end

    local trackCount = reaper.CountTracks(0)

    if mode < 3 then
      for i = 0, trackCount - 1 do
        local track = reaper.GetTrack(0, i)
        local _, trackName = reaper.GetTrackName(track)
        local itemCount = reaper.CountTrackMediaItems(track)

        if mode == 1 then
          if trackName:lower():find(text:lower()) then
            table.insert(search_results, { name = "[Piste] " .. trackName, track = track, selected = false })
          else
            goto continue_track
          end
        else
          for j = 0, itemCount - 1 do
            local item = reaper.GetTrackMediaItem(track, j)
            local take = reaper.GetActiveTake(item)
            local isMuted = reaper.GetMediaItemInfo_Value(item, "B_MUTE") == 1
            local include = false
            local label = ""

            if mode == 0 and take then
              local _, takeName = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)
              if takeName:lower():find(text:lower()) then
                include = true
                label = takeName .. " [" .. trackName .. "]"
              end
            elseif mode == 2 and isMuted then
              local takeName = take and select(2, reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)) or "(no take)"
              include = true
              label = takeName .. " [" .. trackName .. "]"
            end

            if include then
              table.insert(search_results, { name = label, item = item, selected = false })
            end
          end
        end
        ::continue_track::
      end
    else
      -- === Take Markers ===
      if text == "" then return end
      for i = 0, trackCount - 1 do
        local track = reaper.GetTrack(0, i)
        local _, trackName = reaper.GetTrackName(track)
        local itemCount = reaper.CountTrackMediaItems(track)

        for j = 0, itemCount - 1 do
          local item = reaper.GetTrackMediaItem(track, j)
          local retval, chunk = reaper.GetItemStateChunk(item, "", false)
          if retval and chunk then
            for line in chunk:gmatch("[^\r\n]+") do
              if line:match("^TKM") then
                local pos, name = line:match('TKM ([^%s]+) "?([^"]*)"?')
                  if name and name:lower():find(text:lower()) then
                   local label = string.format("Piste %d '%s', Item %d: %s", i+1, trackName, j+1, name)
                  --table.insert(search_results_tkm, { name = label, item = item })
                  table.insert(search_results_tkm, { name = label, item = item, tkm_pos = tonumber(pos) })
                end
              end
            end
          end
        end
      end
    end
  end

  -- Boucle d'affichage
  local function loop()
    local visible
    visible, open = reaper.ImGui_Begin(ctx, "Recherche d'Items", open, reaper.ImGui_WindowFlags_AlwaysAutoResize())

    if visible then
      reaper.ImGui_Text(ctx, "🔍 Recherche (Appuyer sur Entrée)")

      local enter_pressed
      enter_pressed, search_text = reaper.ImGui_InputText(ctx, "##search", search_text, reaper.ImGui_InputTextFlags_EnterReturnsTrue())

      local changed_mode
      changed_mode, selected_mode = reaper.ImGui_Combo(ctx, "Mode", selected_mode, table.concat(search_modes, "\0") .. "\0")

      local changed_select_multiple
      changed_select_multiple, select_multiple = reaper.ImGui_Checkbox(ctx, "Sélection multiple", select_multiple)

      if enter_pressed or changed_mode or changed_select_multiple then
        SearchProjectItems(search_text, selected_mode)
      end

      reaper.ImGui_Separator(ctx)

      local results_list = selected_mode == 3 and search_results_tkm or search_results

      for i, result in ipairs(results_list) do
        if select_multiple then
          local changed
          changed, result.selected = reaper.ImGui_Checkbox(ctx, "##chk_" .. i, result.selected)
          reaper.ImGui_SameLine(ctx)
          reaper.ImGui_Text(ctx, result.name)
        else
          if reaper.ImGui_Selectable(ctx, result.name) then
            reaper.Main_OnCommand(40289, 0) -- Unselect all items
            reaper.Main_OnCommand(40297, 0) -- Unselect all tracksæ

            if result.track then
              reaper.SetTrackSelected(result.track, true)
            elseif result.item then
              reaper.SetMediaItemSelected(result.item, true)
            end

            reaper.Main_OnCommand(40913, 0)
            reaper.UpdateArrange()
            if (selected_mode == 0 or selected_mode == 3) and result.item then
              reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_SELTRKWITEM"), 0) -- sélectionner la piste de l'item
              reaper.Main_OnCommand(40913, 0) -- zoom horizontal
              reaper.Main_OnCommand(40914, 0) -- scroll vertical
              reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_HZOOMITEMS"), 0) -- focus horizontal sur item
            end
            if selected_mode == 3 and result.item then
              if result.tkm_pos then
                local item_pos = reaper.GetMediaItemInfo_Value(result.item, "D_POSITION")
                local goto_pos = item_pos + result.tkm_pos
                reaper.SetEditCurPos(goto_pos, true, true) -- positionner le curseur, déplacer la vue
              end
            end
          end
        end
      end

      if select_multiple and #results_list > 0 then
        reaper.ImGui_Separator(ctx)
        if reaper.ImGui_Button(ctx, "Sélectionner les items cochés") then
          reaper.Main_OnCommand(40289, 0)
          for _, result in ipairs(results_list) do
            if result.selected then
              if result.track then
                  reaper.SetTrackSelected(result.track, true)
                elseif result.item then
                  reaper.SetMediaItemSelected(result.item, true)
                end
              
                reaper.UpdateArrange()
              
                -- 🔽 Exécuter uniquement si on est en mode "Nom du Take"
                if selected_mode == 0 and result.item then
                  reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_SELTRKWITEM"), 0) -- sélectionner la piste de l'item
                  reaper.Main_OnCommand(40913, 0) -- zoom horizontal
                  reaper.Main_OnCommand(40914, 0) -- scroll vertical
                  reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_HZOOMITEMS"), 0) -- focus horizontal sur item
                end
              end
            end
          end
        end

      reaper.ImGui_End(ctx)
    end

    if open then
      reaper.defer(loop)
    end
  end

  reaper.defer(loop)
end
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
-- Function: MoveTracksToSelTracks()
-- Description:
--   Opens an ImGui window listing all project tracks.
--   Moves the currently selected tracks just below
--   the one chosen in the list.
----------------------------------------
function MoveTracksToSelTracks()

  local function SaveTracks()
    local t = {}
    local count = reaper.CountTracks(0)
    for i = 0, count - 1 do
      local track = reaper.GetTrack(0, i)
      local _, name = reaper.GetTrackName(track)
      local depth = reaper.GetTrackDepth(track)
      local indent = string.rep("-", depth)
      local color = reaper.GetMediaTrackInfo_Value(track, "I_CUSTOMCOLOR")
      local display = string.format("%02d: %s%s", i + 1, indent, name)
      t[#t + 1] = {
        track = track,
        index = i,
        color = color > 0 and reaper.ImGui_ColorConvertNative(color) or 0,
        name = display
      }
    end
    return t
  end

  local function GetSelectedTrackIndices()
    local t = {}
    for i = 0, reaper.CountSelectedTracks(0) - 1 do
      local tr = reaper.GetSelectedTrack(0, i)
      t[#t + 1] = reaper.GetMediaTrackInfo_Value(tr, "IP_TRACKNUMBER") - 1
    end
    table.sort(t)
    return t
  end

  local function MoveSelectedTracksBelow(target_idx)
    local selected = GetSelectedTrackIndices()
    if #selected == 0 then return end

    for _, idx in ipairs(selected) do
      if idx == target_idx then return end -- ignore if target in selection
    end

    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)
    reaper.ReorderSelectedTracks(target_idx + 1, 2)
    reaper.PreventUIRefresh(-1)
    reaper.Undo_EndBlock("Move selected tracks below chosen track", -1)
    reaper.UpdateArrange()
    createitemsfromtracks()
  end

  local function colorSquare(ctx, color)
    color = (color << 8) | 0xff
    local draw_list = reaper.ImGui_GetWindowDrawList(ctx)
    local x, y = reaper.ImGui_GetCursorScreenPos(ctx)
    local size = reaper.ImGui_GetTextLineHeight(ctx)
    reaper.ImGui_DrawList_AddRectFilled(draw_list, x, y, x + size, y + size, color)
    local pad = reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding())
    reaper.ImGui_SetCursorScreenPos(ctx, x + size + pad, y)
  end

  local ctx = reaper.ImGui_CreateContext("Move Selected Tracks Below...")
  local current_track = nil
  local tracks = {}
  local quit = false

  local function Loop()
    local visible, open = reaper.ImGui_Begin(ctx, "Move Selected Tracks Below...", true, reaper.ImGui_WindowFlags_NoCollapse())
    if visible then
      local w = reaper.ImGui_GetWindowWidth(ctx)
      tracks = SaveTracks()
      reaper.ImGui_SetNextItemWidth(ctx, w - 25)
      if not current_track and tracks[1] then current_track = 1 end

      if reaper.ImGui_BeginCombo(ctx, "##combo_tracks", "") then
        for i, v in ipairs(tracks) do
          reaper.ImGui_PushID(ctx, i)
          colorSquare(ctx, v.color)
          if reaper.ImGui_Selectable(ctx, v.name, current_track == i) then
            current_track = i
          end
          reaper.ImGui_PopID(ctx)
        end
        reaper.ImGui_EndCombo(ctx)
      end

      local pad_x, pad_y = reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding())
      local v = tracks[current_track]
      if v then
        colorSquare(ctx, v.color)
        reaper.ImGui_Text(ctx, v.name)
      end

      reaper.ImGui_Dummy(ctx, 0, 15)
      local button_w = w > 270 and w / 3 or w - 15
      if w > 270 then reaper.ImGui_SameLine(ctx, w / 6) end
      if reaper.ImGui_Button(ctx, "Move", button_w, 25) then
        if current_track then
          MoveSelectedTracksBelow(tracks[current_track].index)
        end
      end
      if w > 270 then reaper.ImGui_SameLine(ctx) end
      if reaper.ImGui_Button(ctx, "Move & Quit", button_w, 25)
        or reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_Enter()) then
        if current_track then
          MoveSelectedTracksBelow(tracks[current_track].index)
        end
        quit = true
      end
    end
    reaper.ImGui_End(ctx)

    if quit or not open then
     pcall(function()
     reaper.ImGui_DestroyContext(ctx)
   end)
    else
      reaper.defer(Loop)
    end
  end

  Loop()
end

  reaper.ImGui_SameLine(ctx)
  if reaper.ImGui_Button(ctx, "Move Tracks") then
    MoveTracksToSelTracks()
  end
  reaper.ImGui_SameLine(ctx)



--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------


local function loop()
  local nb_lignes = math.ceil(#palette_gui / conf.number_x)
  --local win_w = conf.number_x * (btn_size + conf.spacing) + conf.spacing   old dimensions  ligne1
  --local win_h = nb_lignes * (btn_size + conf.spacing) + conf.spacing + 140 --old dimension ligne2

  ---- F I N D ----
  if show_tracks_search then
    DrawTracksSearchWindow()
  end
  -----------------
  
  if first_frame then
    --reaper.ImGui_SetNextWindowSize(ctx, win_w, win_h) ---- old dimension Ligne3
    reaper.ImGui_SetNextWindowSize(ctx,980, 90)
    createitemsfromtracks()
    local guideTrack = FindTracksGuide()
    if guideTrack then
      reaper.SetOnlyTrackSelected(guideTrack)
      reaper.ReorderSelectedTracks(0, 0)
      reaper.Main_OnCommand(40008, 0) -- Pin track to top and un pin other
    end
    createitemsfromtracks()
    first_frame = false
  end

  local visible, open = reaper.ImGui_Begin(ctx, 'TRACKMANAGER⌘   Colorizing ┤   ├TRKS < sorting> ITEMS┤  ├C R E A T I N G (TRKs & Spacer┤ ├MOVE      🀰Tracks🀰    SELECT┤         ____VIEW_  ├F  I  N  D┤   Utils', true)
  if not visible then
    if open then reaper.defer(loop) end
    return
  end

-- Bouton Help
-- Créer la couleur verte en U32
local green_normal  = reaper.ImGui_ColorConvertDouble4ToU32(0.1, 0.5, 0.2, 1.0)
local green_hovered = reaper.ImGui_ColorConvertDouble4ToU32(0.3, 1.0, 0.3, 1.0)
local green_active  = reaper.ImGui_ColorConvertDouble4ToU32(0.2, 0.9, 0.2, 1.0)

-- Appliquer les couleurs
reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), green_normal)
reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), green_hovered)
reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), green_active)
-- === Bouton principal ===
if reaper.ImGui_Button(ctx, 'HELP') then
  show_trk_window = true
end
reaper.ImGui_PopStyleColor(ctx, 3)


-- === Nouvelle fenêtre ImGui à la place du popup ===
if show_trk_window then
  local visible, open = reaper.ImGui_Begin(ctx, "HELP: Manual & Explanations", true)

  if visible then
         reaper.ImGui_Text(ctx, "TRACKMANAGER IS A TOOL FORE VISUALIZE AND\n" ..
         "  MANIPULATE YOUR TRACKS FROM RESPECTIVE\n" ..
         "     ITEMS IN THE FIRST 'GUIDE' TRACKS")
    reaper.ImGui_Separator(ctx)
    reaper.ImGui_Separator(ctx)
       reaper.ImGui_Text(ctx, "Click the buttons below to see their description")
    reaper.ImGui_Separator(ctx)
    if reaper.ImGui_Button(ctx, "Item=Track") then
      reaper.ShowMessageBox("Source Item Color from Track Color", "Item=Track - Info", 0)
    end
    
reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(),        0xCC8400FF) -- orange vif 0xFFA100FF
reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0xFFB733FF) -- survol (plus clair)
reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(),  0xFFA100FF) -- clic (plus foncé)

-----

  if reaper.ImGui_Button(ctx, "▶ ◀") then
      reaper.ShowMessageBox("Move Forward & Backward in Shuffle Mode Items of 'TRACKS' to [Re-Order] the respectives TRACKS in the session", "▶ ◀ - Info", 0)
  end
      reaper.ImGui_SameLine(ctx)
  if reaper.ImGui_Button(ctx, "Re-Order") then
      reaper.ShowMessageBox("Must be used after Shuffling Items of 'TRACKS' to Sync Order Between Items & [Tracks] in the session", "Re-Order - Info", 0)
  end
      reaper.ImGui_SameLine(ctx)
  if reaper.ImGui_Button(ctx, "abc") then
reaper.ShowMessageBox(
    "Sorts / arranges the session selected[Tracks] in alphabetical order.\n" ..
    "Your session is saved when launching, and may be quickly reloaded with " ..
    "'RevertToSaved.lua' script by MARIOW available with this ReaPack repository\n" ..
    "https://github.com/Geeksound/Reaper_Scripts-Mariow/raw/main/index.xml\n" ..
    "You may visit :\n" ..
    "https://github.com/Geeksound/Reaper_Scripts-Mariow",
    "abc - Info", 0)
  end
  reaper.ImGui_PopStyleColor(ctx, 3)
    if reaper.ImGui_Button(ctx, 'Trk ✚     [   ] ✚')then
    reaper.ShowMessageBox("Add track & Name  / Add a Spacer after Selected [Track] / Pressing [ALT] key let you do the opposite (Delete)", "Info", 0)
    end
  -- Déclaration de la police agrandie (à faire **une seule fois** au début du script, avant ta boucle principale)
  if not bigFont then
    bigFont = reaper.ImGui_CreateFont('sans-serif', 18) -- Taille modifiable ici
    reaper.ImGui_Attach(ctx, bigFont)
  end
  
  -- **Bouton CreateTracksFrom-Items en rouge**
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0xFF0000FF)         -- rouge (RRGGBBAA)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0xCC0000FF)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), 0x990000FF)
  
  if reaper.ImGui_Button(ctx, 'TRKs') then
     reaper.ShowMessageBox("This button creates [Tracks] based on\nthe order of" ..
     " the items in the “TRACKS” track.\n It opens a window allowing you to confirm or cancel the action ", "TRKs - Info", 0)
  end
  
  reaper.ImGui_PopStyleColor(ctx, 3)  
  -- Créer la couleur verte en U32
  local green_normal  = reaper.ImGui_ColorConvertDouble4ToU32(0.1, 0.5, 0.2, 1.0)
  local green_hovered = reaper.ImGui_ColorConvertDouble4ToU32(0.3, 1.0, 0.3, 1.0)
  local green_active  = reaper.ImGui_ColorConvertDouble4ToU32(0.2, 0.9, 0.2, 1.0)
  
  -- Appliquer les couleurs
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), green_normal)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), green_hovered)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), green_active)

   reaper.ImGui_SameLine(ctx)
   if reaper.ImGui_Button(ctx, '✖Prefix & ↻') then
     reaper.ShowMessageBox("May be used to refresh Items 'TRACKS' View and "..
     "Removes any prefix that may precede the [Track] name to ensure the proper functioning of the “FOCUS” feature", "✖Prefix - Info", 0)
   end
     reaper.ImGui_PopStyleColor(ctx, 3)
     reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(),        0xCC8400FF) -- orange vif 0xFFA100FF
     reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0xFFB733FF) -- survol (plus clair)
     reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(),  0xFFA100FF) -- clic (plus foncé)
     
   reaper.ImGui_SameLine(ctx)
   
     if reaper.ImGui_Button(ctx, '⇅', 20, 20) then
         reaper.ShowMessageBox("Move Selected Track Down, and Up by pressing [ALT]", "Info", 0)
    end
  -- Retirer les styles après le bouton
  reaper.ImGui_PopStyleColor(ctx, 3)
     reaper.ImGui_SameLine(ctx)
    if reaper.ImGui_ArrowButton(ctx, '##Left', reaper.ImGui_Dir_Left()) then
    reaper.ShowMessageBox("Select Tracks , SHIFT may be used to extend selection", "◀ - Info", 0)
      end
    reaper.ImGui_SameLine(ctx, nil, 05)
    if reaper.ImGui_ArrowButton(ctx, '##Right', reaper.ImGui_Dir_Right()) then
    reaper.ShowMessageBox("Select Tracks , SHIFT may be used to extend selection", "▶ - Info", 0)
      end
  ----------- End Refresh&Prefix -------------- 
    if reaper.ImGui_Button(ctx, 'FOCUS') then
    reaper.ShowMessageBox("The “FOCUS” function allows you to toggle the view of the item on “TRACKS” "..
    " that corresponds to the [Track] that it represents", "FOCUS - Info", 0)
    end
    reaper.ImGui_SameLine(ctx)
    if reaper.ImGui_Button(ctx, 'ALL') then
    reaper.ShowMessageBox("Toggle Global Project view and Horizontal Zoom of Items in 'TRACKS'", "ALL - Info", 0)
    end
    reaper.ImGui_SameLine(ctx)
    if reaper.ImGui_Button(ctx, 'FD1     FD2') then
    reaper.ShowMessageBox("A simple yet advanced tool for searching Items, Tracks, Take Markers, etc.,"..
    " in your session to quickly locate and navigate to them", "FD1&FD2 - Info", 0)
    end
        reaper.ImGui_Text(ctx, "The last checkbox allows you\n to show or hide the “TRACKS” track")
    reaper.ImGui_Separator(ctx)
    if reaper.ImGui_Button(ctx, "Close Window") then
      show_trk_window = false
    end
  end

  reaper.ImGui_End(ctx)

  if not open then
    show_trk_window = false
  end
end

--reaper.ImGui_PopStyleColor(ctx, 3)
    reaper.ImGui_SameLine(ctx, nil, 05)
-- Définir la couleur jaune pour le texte🀰
reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(),  reaper.ImGui_ColorConvertDouble4ToU32(1.0, 1.0, 0.0, 1.0)) -- Jaune

-- === Boutons radio ===
if reaper.ImGui_RadioButton(ctx, 'Trk', apply_to_tracks) then
  apply_to_tracks = true
  apply_to_items = false
end

  reaper.ImGui_SameLine(ctx, nil, 5)

  if reaper.ImGui_RadioButton(ctx, 'Clip', apply_to_items) then
    apply_to_tracks = false
    apply_to_items = true
  end

  reaper.ImGui_SameLine(ctx, nil, 10)

-- === Bouton de commande ===
  if reaper.ImGui_Button(ctx, 'Item=Trk') then
    reaper.Main_OnCommand(reaper.NamedCommandLookup('_SWS_ITEMTRKCOL'), 0)
    reaper.Main_OnCommand(40707,0)
    reaper.Main_OnCommand(41337,0)
  end

  reaper.ImGui_SameLine(ctx, nil, 15)

---------------- ITEM FORWARD & BACKWARD ------------------------

reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(),        0xCC8400FF) -- orange vif 0xFFA100FF
reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0xFFB733FF) -- survol (plus clair)
reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(),  0xFFA100FF) -- clic (plus foncé)

-----

  if reaper.ImGui_Button(ctx, "▶") then
    MoveItemForward()
  end
  reaper.ImGui_SameLine(ctx)
  if reaper.ImGui_Button(ctx, "◀") then
    MoveItemBackward()
  end
  reaper.ImGui_SameLine(ctx)
 --------------
 reaper.ImGui_PopStyleColor(ctx)
 -- Bouton Rebuild
   if reaper.ImGui_Button(ctx, 'Re-Order') then
    ReorderTracksByItems()
  end
      reaper.ImGui_SameLine(ctx, nil, 05)
  if reaper.ImGui_Button(ctx, "abc") then
    AlphabeticalSortSelectedTracksToggle()
  end
  reaper.ImGui_PopStyleColor(ctx, 3) -- On retire le chgt de couleur


  reaper.ImGui_SameLine(ctx, nil, 15)
  -- Autres boutons
-- Vérifie si Alt (Option sur Mac) est pressé
local mods = reaper.ImGui_GetKeyMods(ctx)
local isAlt = (mods & reaper.ImGui_Mod_Alt()) ~= 0

-- Change le label selon la touche Option
local label = isAlt and 'Trk ⌫' or 'Trk ✚'

if reaper.ImGui_Button(ctx, label) then
  if isAlt then
    deltrack() -- ta fonction à définir
  else
    addtrack()
  end
end
  ImGui_HelpMarker(ctx, Texte1)
reaper.ImGui_SameLine(ctx, nil, 5)

-- Vérifie si Alt (Option sur Mac) est pressé
local mods = reaper.ImGui_GetKeyMods(ctx)
local isAlt = (mods & reaper.ImGui_Mod_Alt()) ~= 0

-- Change l'icône selon la touche Option
local label = isAlt and '[   ] ⌫' or '[   ] ✚'

if reaper.ImGui_Button(ctx, label) then
  if isAlt then
    delspacer()
  else
    addspacer()
  end
end
  ImGui_HelpMarker(ctx, Texte2)

  if not bigFont then
   bigFont = reaper.ImGui_CreateFont('sans-serif', 18) -- Taille modifiable ici
  reaper.ImGui_Attach(ctx, bigFont)
  end

  reaper.ImGui_SameLine(ctx, nil, 10)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0xFF0000FF)         -- rouge (RRGGBBAA)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0xCC0000FF)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), 0x990000FF)

  if reaper.ImGui_Button(ctx, 'TRKs') then
    show_confirm_popup = true
  end

  reaper.ImGui_PopStyleColor(ctx, 3)

  if show_confirm_popup then
    reaper.ImGui_OpenPopup(ctx, "Confirmer la création")
  end

  if reaper.ImGui_BeginPopupModal(ctx, "Confirmer la création", true) then

  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), 0xFFFF00FF) -- Jaune (RRGGBBAA)
  reaper.ImGui_PushFont(ctx, bigFont,16)

  reaper.ImGui_TextWrapped(ctx,
    "⚠️ Attention, ceci va recréer des pistes vierges basées sur l'ordonnancement des Items de la piste TRACKS !\n\n" ..
    "Êtes-vous sûr de vouloir faire cela ?")

  reaper.ImGui_PopFont(ctx)
  reaper.ImGui_PopStyleColor(ctx)

  reaper.ImGui_Separator(ctx)

  if reaper.ImGui_Button(ctx, "OK") then
    show_confirm_popup = false
    reaper.ImGui_CloseCurrentPopup(ctx)
    createTracksFromItems()
  end

  reaper.ImGui_SameLine(ctx, nil, 20)

  if reaper.ImGui_Button(ctx, "Cancel") then
    show_confirm_popup = false
    reaper.ImGui_CloseCurrentPopup(ctx)
  end

  reaper.ImGui_EndPopup(ctx)
end
   
  reaper.ImGui_SameLine(ctx, nil, 15)    
-- Récupère les modificateurs clavier (Shift / Ctrl / Alt / Cmd)
local mods = reaper.ImGui_GetKeyMods(ctx)
local isAlt = (mods & reaper.ImGui_Mod_Alt()) ~= 0  -- Sur Mac, "Option" = Alt

  
-------------- VIEW Functions ______________
  reaper.ImGui_SameLine(ctx)
  -- Bouton Refresh View
  local green_normal  = reaper.ImGui_ColorConvertDouble4ToU32(0.1, 0.5, 0.2, 1.0)
  local green_hovered = reaper.ImGui_ColorConvertDouble4ToU32(0.3, 1.0, 0.3, 1.0)
  local green_active  = reaper.ImGui_ColorConvertDouble4ToU32(0.2, 0.9, 0.2, 1.0)

  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), green_normal)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), green_hovered)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), green_active)

  if reaper.ImGui_Button(ctx, '✖Prefix & ↻') then
    --createitemsfromtracks()
    delprefixonTrackName()
    dofile(script_path)
  end
    reaper.ImGui_PopStyleColor(ctx, 3)
-----------------------------------------------------------------------------------------------------------
---------------------------------------- orange move track with alt reverse order -------------------------
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(),        0xCC8400FF) -- orange vif 0xFFA100FF
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0xFFB733FF) -- survol (plus clair)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(),  0xFFA100FF) -- clic (plus foncé)
    
  reaper.ImGui_SameLine(ctx)
  
  -- Bouton unique (Down)
  --if reaper.ImGui_ArrowButton(ctx, '##Down', reaper.ImGui_Dir_Down()) then
    if reaper.ImGui_Button(ctx, '⇅', 20, 20) then
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_SAVESEL"), 0)
  
    if isAlt then
      -- 🟢 Action "UP" quand Alt/Option est enfoncé
      reaper.Main_OnCommand(43647, 0)
    else
      -- 🔵 Action "DOWN" normale
      reaper.Main_OnCommand(43648, 0)
    end
  
    createitemsfromtracks()
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_RESTORESEL"), 0)
    reaper.Main_OnCommand(40913, 0) -- Zoom sur sélection (piste)
  end
    ImGui_HelpMarker(ctx, Texte3)
  
      reaper.ImGui_SameLine(ctx, nil, 05)
  
  if reaper.ImGui_Button(ctx, "Move Tracks") then
    MoveTracksToSelTracks()
  end
    ImGui_HelpMarker(ctx, Texte4)
  reaper.ImGui_SameLine(ctx)

----------- End Refresh -------------------
  
    reaper.ImGui_SameLine(ctx, nil, 05)
    reaper.ImGui_PopStyleColor(ctx, 3)
--------------- ARROWS L/R & SHIFT
  if reaper.ImGui_ArrowButton(ctx, '##Left', reaper.ImGui_Dir_Left()) then
  local keyMods = reaper.ImGui_GetKeyMods(ctx)
  local shiftDown = (keyMods & reaper.ImGui_Mod_Shift()) ~= 0
  
  if shiftDown then
  ---- Si SHIFT est enfoncé : exécute la commande_XENAKIOS_SELPREVTRACKKEEP
  local commandID = reaper.NamedCommandLookup("_XENAKIOS_SELPREVTRACKKEEP")
         if commandID ~= 0 then
             reaper.Main_OnCommand(commandID, 0)
         else
             reaper.ShowMessageBox("Commande '_XENAKIOS_SELPREVTRACKKEEP' introuvable !", "Erreur", 0)
         end
     else
         -- Sinon : sélectionne la piste suivante normalement
      reaper.Main_OnCommand(40286,0)
  end
        reaper.Main_OnCommand(40913, 0) -- Zoom sur sélection (piste)
        end
  reaper.ImGui_SameLine(ctx)    reaper.ImGui_SameLine(ctx, nil, 05)  
if reaper.ImGui_ArrowButton(ctx, '##right', reaper.ImGui_Dir_Right()) then
    local keyMods = reaper.ImGui_GetKeyMods(ctx)
    local shiftDown = (keyMods & reaper.ImGui_Mod_Shift()) ~= 0

    if shiftDown then
        -- Si SHIFT est enfoncé : exécute la commande "_XENAKIOS_SELNEXTTRACKKEEP"
        local commandID = reaper.NamedCommandLookup("_XENAKIOS_SELNEXTTRACKKEEP")
        if commandID ~= 0 then
            reaper.Main_OnCommand(commandID, 0)
        else
            reaper.ShowMessageBox("Commande '_XENAKIOS_SELNEXTTRACKKEEP' introuvable !", "Erreur", 0)
        end
    else
        reaper.Main_OnCommand(40285, 0)
    end
    reaper.Main_OnCommand(40913, 0)
end
-------------- end Arrows L/R ---------
 ------------------------------ 
  reaper.ImGui_SameLine(ctx, nil, 15)
  if reaper.ImGui_Button(ctx, 'FOCUS') then MirrorSelection() end
    ImGui_HelpMarker(ctx, Texte5)
  reaper.ImGui_SameLine(ctx, nil, 05)
  if reaper.ImGui_Button(ctx, 'ALL') then viewall() end
    reaper.ImGui_SameLine(ctx)

    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(),  reaper.ImGui_ColorConvertDouble4ToU32(1.0, 1.0, 0.0, 1.0)) -- Jaune
  if reaper.ImGui_Button(ctx, "FD1") then
    show_tracks_search = true
  end
        reaper.ImGui_SameLine(ctx, nil, 05)
    if reaper.ImGui_Button(ctx, "FD2") then
      RechercheItemsGUI(ctx)
    end
  reaper.ImGui_PopStyleColor(ctx)
    reaper.ImGui_SameLine(ctx)
  -- Checkbox GUIDE TRACKS
  reaper.ImGui_SameLine(ctx, nil, 05)
  reaper.ImGui_Text(ctx, "View")
  reaper.ImGui_SameLine(ctx)
  local changed
  changed, show_tracks_guide = reaper.ImGui_Checkbox(ctx, "##show_guide", show_tracks_guide)
  if changed then toggleTracksGuideVisibility(show_tracks_guide) end


  reaper.ImGui_Separator(ctx)

  -- gui colors
  for i, color in ipairs(palette_gui) do
    local r, g, b = table.unpack(color)
    local colU32 = reaper.ImGui_ColorConvertDouble4ToU32(r, g, b, 1.0)

    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), colU32)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), colU32)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), colU32)

    local cx, cy = reaper.ImGui_GetCursorScreenPos(ctx)

    if reaper.ImGui_Button(ctx, "##col"..i, btn_size, btn_size) then
      local applied = palette_appliquee[i]
      apply_color(applied[1], applied[2], applied[3])
    end

    if reaper.ImGui_IsItemHovered(ctx) then
      local dl = reaper.ImGui_GetWindowDrawList(ctx)
      reaper.ImGui_DrawList_AddRect(dl, cx, cy, cx + btn_size, cy + btn_size, 0xFFFFFFFF)
    end

    reaper.ImGui_PopStyleColor(ctx, 3)

    if (i % conf.number_x) ~= 0 then
      reaper.ImGui_SameLine(ctx)
    end
  end

  reaper.ImGui_End(ctx)


  if open then
    reaper.defer(loop)
  end
end

reaper.defer(loop)

