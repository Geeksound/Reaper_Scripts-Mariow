--[[
@description View-FieldRecorder-Metadatas
@version 1.2.1
@author Mariow
@changelog
- Fixed malformed header block
@provides
[main] Metadatas/View-FieldRecorder-Metadatas.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags items, metadata, source properties
@about
# View-FieldRecorder-Metadatas
Contextual display of selected item metadata for Reaper 7.0.
This script was developed with the help of GitHub Copilot.
--]]

local r = reaper

local function Msg(str)
  r.ShowConsoleMsg(tostring(str) .. "\n")
end

local function GetMetadata(src, tag)
  local ok, val = r.GetMediaFileMetadata(src, tag)
  if not ok or val == "" then
    return "[non trouvé ou vide]"
  end
  return val
end

-- Affiche les tags statiques
local function PrintStaticTags(src)
  local tags = {
    "BWF:Description",
    "aSCENE",
    "aTAKE",
    "aTAPE",
    "aSPEED",
    "aTAG",
    "aNOTE",
    "aTYP",
    "BWF:OriginationDate",
    "BWF:OriginationTime",
    "BWF:TimeReference",
    "IXML:PROJECT",
    "IXML:SCENE",
    "IXML:TAKE",
    "IXML:TAPE",
    "IXML:BEXT:BWF_DESCRIPTION",
    "IXML:BEXT:BWF_ORIGINATOR",
    "IXML:TRACK_LIST:TRACK_COUNT"
  }
  for _, tag in ipairs(tags) do
    Msg(string.format("%s : %s", tag, GetMetadata(src, tag)))
  end
end

-- Affiche tous les ALL_TRK_NAME:DATA:ACTIVE de 1 à maxIndex (ici 24)
local function PrintActiveTracksStatus(src, maxIndex)
  for i = 1, maxIndex do
    local tag = (i == 1) and
      "IXML:AATON_CANTAR:ALL_TRK_NAME:DATA:ACTIVE" or
      ("IXML:AATON_CANTAR:ALL_TRK_NAME:DATA:ACTIVE:" .. i)
    local val = GetMetadata(src, tag)
    Msg(string.format("%s : %s", tag, val))
  end
end

-- Compte les DISARMED avant un index donné
local function CountDisarmedBefore(trackIndex, src)
  local count = 0
  for i = 1, trackIndex -1 do
    local tag = (i == 1) and
      "IXML:AATON_CANTAR:ALL_TRK_NAME:DATA:ACTIVE" or
      ("IXML:AATON_CANTAR:ALL_TRK_NAME:DATA:ACTIVE:" .. i)
    local val = GetMetadata(src, tag)
    if val == "DISARMED" then
      count = count + 1
    end
  end
  return count
end

-- Récupère le nom de la piste selon l’index ajusté (piste active)
local function GetTrackName(trackIndex, src)
  -- Statut actif ou DISARMED
  local activeTag = (trackIndex == 1) and
    "IXML:AATON_CANTAR:ALL_TRK_NAME:DATA:ACTIVE" or
    ("IXML:AATON_CANTAR:ALL_TRK_NAME:DATA:ACTIVE:" .. trackIndex)
  local status = GetMetadata(src, activeTag)

  if status == "DISARMED" then
    return "DISARMED"
  elseif status == "YES" then
    local disarmedBefore = CountDisarmedBefore(trackIndex, src)
    local adjustedIndex = trackIndex - disarmedBefore
    local nameTag = (adjustedIndex == 1) and
      "IXML:TRACK_LIST:TRACK:NAME" or
      ("IXML:TRACK_LIST:TRACK:NAME:" .. adjustedIndex)
    local name = GetMetadata(src, nameTag)
    if name == "[non trouvé ou vide]" then
      return "[non trouvée]"
    else
      return name
    end
  else
    return "[non trouvée]"
  end
end

local function Main()
  r.ClearConsole()

  local item = r.GetSelectedMediaItem(0, 0)
  if not item then
    Msg("Aucun item sélectionné.")
    return
  end
  local take = r.GetActiveTake(item)
  if not take then
    Msg("Aucun take actif sur l'item.")
    return
  end
  local src = r.GetMediaItemTake_Source(take)
  if not src then
    Msg("Impossible d'obtenir la source média.")
    return
  end
  local filepath = r.GetMediaSourceFileName(src, "")

  Msg("=== MÉTADONNÉES ===")
  Msg("Fichier : " .. filepath)
  Msg("")

  local pcm_src = r.PCM_Source_CreateFromFile(filepath)
  if not pcm_src then
    Msg("Impossible de charger la source PCM depuis le fichier.")
    return
  end

  -- Affiche les tags fixes
  PrintStaticTags(pcm_src)
  Msg("")

  -- Affiche la section complète ALL_TRK_NAME:DATA:ACTIVE de 1 à 24 (comme dans ton exemple)
  PrintActiveTracksStatus(pcm_src, 24)
  Msg("")

  -- Récupérer le nombre total de pistes à afficher (ici on se base sur TRACK_COUNT)
  local ok, trackCountStr = r.GetMediaFileMetadata(pcm_src, "IXML:TRACK_LIST:TRACK_COUNT")
  local trackCount = tonumber(trackCountStr) or 0

  Msg("--- NOMS DES PISTES ---")
  for i = 1, trackCount do
    local name = GetTrackName(i, pcm_src)
    Msg(string.format("Piste %d (iXML) : %s", i, name))
  end

  r.PCM_Source_Destroy(pcm_src)
end

Main()

