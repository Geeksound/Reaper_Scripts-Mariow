--[[
@description ViewFile-FieldRecorder-Metadatas
@version 1.0
@author Mariow
@license MIT
@changelog
  v1.0 (2025-06-07)
  - Initial release
@provides
  [main] Metadatas/ViewFile-FieldRecorder-Metadatas.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags items metadata source properties
@about
  # ViewFile-FieldRecorder-Metadatas
  
  Contextual display of selected item metadata for REAPER 7.0.

  This script was developed with the help of GitHub Copilot.
--]]



local r = reaper

function Msg(str)
  r.ShowConsoleMsg(tostring(str) .. "\n")
end

function ReadMetadata(filepath)
  local src = r.PCM_Source_CreateFromFile(filepath)
  if not src then
    Msg("Erreur : impossible de charger le fichier en tant que PCM source.")
    return
  end

  Msg("=== METADONNÉES DU FICHIER ===")
  Msg("Fichier : " .. filepath .. "\n")

  -- Liste des tags classiques BWF et iXML
  local tags = {
    "BWF:Description",
    "BWF:OriginationDate",
    "BWF:OriginationTime",
    "BWF:TimeReference",
    "IXML:PROJECT",
    "IXML:SCENE",
    "IXML:TAKE",
    "IXML:TAPE",
    "IXML:BEXT:BWF_ORIGINATION_DATE",
    "IXML:BEXT:BWF_ORIGINATION_TIME",
    "IXML:BEXT:BWF_DESCRIPTION",
    "IXML:BEXT:BWF_ORIGINATOR",
    "IXML:BEXT:BWF_ORIGINATOR_REFERENCE",
    "IXML:BEXT:BWF_TIME_REFERENCE_LOW",
    "IXML:BEXT:BWF_TIME_REFERENCE_HIGH",
    "Generic:StartOffset",
    "IXML:TRACK_LIST:TRACK_COUNT",

    -- Tous les ACTIVE jusqu'à 24
    "IXML:AATON_CANTAR:ALL_TRK_NAME:DATA:ACTIVE",
    "IXML:AATON_CANTAR:ALL_TRK_NAME:DATA:ACTIVE:2",
    "IXML:AATON_CANTAR:ALL_TRK_NAME:DATA:ACTIVE:3",
    "IXML:AATON_CANTAR:ALL_TRK_NAME:DATA:ACTIVE:4",
    "IXML:AATON_CANTAR:ALL_TRK_NAME:DATA:ACTIVE:5",
    "IXML:AATON_CANTAR:ALL_TRK_NAME:DATA:ACTIVE:6",
    "IXML:AATON_CANTAR:ALL_TRK_NAME:DATA:ACTIVE:7",
    "IXML:AATON_CANTAR:ALL_TRK_NAME:DATA:ACTIVE:8",
    "IXML:AATON_CANTAR:ALL_TRK_NAME:DATA:ACTIVE:9",
    "IXML:AATON_CANTAR:ALL_TRK_NAME:DATA:ACTIVE:10",
    "IXML:AATON_CANTAR:ALL_TRK_NAME:DATA:ACTIVE:11",
    "IXML:AATON_CANTAR:ALL_TRK_NAME:DATA:ACTIVE:12",
    "IXML:AATON_CANTAR:ALL_TRK_NAME:DATA:ACTIVE:13",
    "IXML:AATON_CANTAR:ALL_TRK_NAME:DATA:ACTIVE:14",
    "IXML:AATON_CANTAR:ALL_TRK_NAME:DATA:ACTIVE:15",
    "IXML:AATON_CANTAR:ALL_TRK_NAME:DATA:ACTIVE:16",
    "IXML:AATON_CANTAR:ALL_TRK_NAME:DATA:ACTIVE:17",
    "IXML:AATON_CANTAR:ALL_TRK_NAME:DATA:ACTIVE:18",
    "IXML:AATON_CANTAR:ALL_TRK_NAME:DATA:ACTIVE:19",
    "IXML:AATON_CANTAR:ALL_TRK_NAME:DATA:ACTIVE:20",
    "IXML:AATON_CANTAR:ALL_TRK_NAME:DATA:ACTIVE:21",
    "IXML:AATON_CANTAR:ALL_TRK_NAME:DATA:ACTIVE:22",
    "IXML:AATON_CANTAR:ALL_TRK_NAME:DATA:ACTIVE:23",
    "IXML:AATON_CANTAR:ALL_TRK_NAME:DATA:ACTIVE:24",

    -- Pour Scorpio
    "IXML:CIRCLED",
    "IXML:HISTORY:CURRENT_FILENAME",
    "IXML:HISTORY:ORIGINAL_FILENAME",
    "IXML:SPEED:TIMESTAMP_SAMPLES_SINCE_MIDNIGHT_LO",
  }

  -- Affichage des métadonnées classiques
  for _, tag in ipairs(tags) do
    local retval, value = r.GetMediaFileMetadata(src, tag)
    if retval and value and value ~= "" then
      Msg(tag .. " : " .. value)
    else
      Msg(tag .. " : [non trouvé ou vide]")
    end
  end

  -- Lecture du nombre total de pistes dans iXML
  local _, trackCountStr = r.GetMediaFileMetadata(src, "IXML:TRACK_LIST:TRACK_COUNT")
  local trackCount = tonumber(trackCountStr) or 0

  -- Fonction pour récupérer le statut actif ou DISARMED d'une piste (1-based)
  local function GetTrackStatus(i)
    local tag = (i == 1) and "IXML:AATON_CANTAR:ALL_TRK_NAME:DATA:ACTIVE" or ("IXML:AATON_CANTAR:ALL_TRK_NAME:DATA:ACTIVE:" .. i)
    local _, val = r.GetMediaFileMetadata(src, tag)
    if val == nil or val == "" then return "[non trouvé ou vide]" end
    return val
  end

  -- Compter le nombre de pistes DISARMED avant l'index i
  local function CountDisarmedBefore(i)
    local count = 0
    for idx = 1, i-1 do
      if GetTrackStatus(idx) == "DISARMED" then count = count + 1 end
    end
    return count
  end

  Msg("\n--- NOMS DES PISTES (fusion BWF et iXML) ---")
  for i = 1, trackCount do
    local status = GetTrackStatus(i)

    if status == "DISARMED" then
      -- Piste DISARMED
      Msg("Track " .. i .. " : DISARMED")
    elseif status == "YES" then
      -- Calcule index ajusté pour noms iXML (enlevant DISARMED)
      local disarmedBefore = CountDisarmedBefore(i)
      local adjustedIndex = i - disarmedBefore

      -- Lire nom piste iXML ajusté
      local ixmlTag = (adjustedIndex == 1) and "IXML:TRACK_LIST:TRACK:NAME" or ("IXML:TRACK_LIST:TRACK:NAME:" .. adjustedIndex)
      local retvalIXML, nameIXML = r.GetMediaFileMetadata(src, ixmlTag)

      -- Lire nom piste BWF en fallback
      local nameBWF = nil
      for _, prefix in ipairs({"d", "s", "a", "g", "r"}) do
        local retvalBWF, name = r.GetMediaFileMetadata(src, prefix .. "TRK" .. i)
        if retvalBWF and name and name ~= "" then
          nameBWF = name
          break
        end
      end

      if retvalIXML and nameIXML and nameIXML ~= "" then
        Msg("Track " .. i .. " (iXML) : " .. nameIXML)
      elseif nameBWF then
        Msg("Track " .. i .. " (BWF) : " .. nameBWF)
      else
        Msg("Track " .. i .. " : [not found]")
      end
    else
      -- Statut inconnu ou vide
      Msg("Track " .. i .. " : [statut inconnu ou non actif]")
    end
  end

  r.PCM_Source_Destroy(src)
end

-- Main
function Main()
  local retval, filepath = r.GetUserFileNameForRead("", "Select an Audio File", "")
  if retval then
    r.ClearConsole()
    ReadMetadata(filepath)
  else
    Msg("No file selected.")
  end
end

Main()

