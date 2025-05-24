-- @description View-FieldRecorder-Metadatas
-- @author Mariow
-- @version 1.1
-- @changelog Renamed
-- @provides
--   [main] Metadatas/View-FieldRecorder-Metadatas.lua
-- @link https://github.com/Geeksound/Reaper_Scripts-Mariow
-- @tags items , metadatatas , source properties
-- @about
--   # View-FieldRecorder-Metadatas
--   Contextual display selected item metadata for Reaper 7.0.
-- This script was developed with the help of GitHub Copilot.


local r = reaper

function Msg(str)
r.ShowConsoleMsg(tostring(str) .. "\n")
end

function ReadMetadataFromFile(filepath)
local src = r.PCM_Source_CreateFromFile(filepath)
if not src then
Msg("Erreur : impossible de charger le fichier en tant que PCM source.")
return
end

Msg("=== MÉTADONNÉES ===")
Msg("Fichier : " .. filepath .. "\n")

local tags = {
"BWF:Description", "BWF:OriginationDate", "BWF:OriginationTime", "BWF:TimeReference",
"IXML:PROJECT", "IXML:SCENE", "IXML:TAKE", "IXML:TAPE",
"IXML:BEXT:BWF_DESCRIPTION", "IXML:BEXT:BWF_ORIGINATOR",
"IXML:TRACK_LIST:TRACK_COUNT",
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

}

for _, tag in ipairs(tags) do
local retval, value = r.GetMediaFileMetadata(src, tag)
if retval and value ~= "" then
Msg(tag .. " : " .. value)
else
Msg(tag .. " : [non trouvé ou vide]")
end
end

local _, trackCountStr = r.GetMediaFileMetadata(src, "IXML:TRACK_LIST:TRACK_COUNT")
local trackCount = tonumber(trackCountStr) or 0

Msg("\n--- NOMS DES PISTES ---")
for i = 1, trackCount do
local ixmlTag = (i == 1) and "IXML:TRACK_LIST:TRACK:NAME" or ("IXML:TRACK_LIST:TRACK:NAME:" .. i)
local retvalIXML, nameIXML = r.GetMediaFileMetadata(src, ixmlTag)

local nameBWF = nil
for _, prefix in ipairs({"d", "s", "a", "g", "r"}) do
local retvalBWF, name = r.GetMediaFileMetadata(src, prefix .. "TRK" .. i)
if retvalBWF and name and name ~= "" then
nameBWF = name
break
end
end

if retvalIXML and nameIXML and nameIXML ~= "" then
Msg("Piste " .. i .. " (iXML) : " .. nameIXML)
elseif nameBWF then
Msg("Piste " .. i .. " (BWF) : " .. nameBWF)
else
Msg("Piste " .. i .. " : [non trouvée]")
end
end

r.PCM_Source_Destroy(src)
end

-- MAIN
function Main()
r.ClearConsole()
local item = r.GetSelectedMediaItem(0, 0)
if not item then
Msg("Aucun item sélectionné.")
return
end

local take = r.GetActiveTake(item)
if not take or r.TakeIsMIDI(take) then
Msg("Erreur : l’item n’a pas de take audio actif.")
return
end

local src = r.GetMediaItemTake_Source(take)
local filepath = r.GetMediaSourceFileName(src, "")

if filepath == "" then
Msg("Erreur : impossible de retrouver le chemin du fichier source.")
return
end

ReadMetadataFromFile(filepath)
end

Main()
