--[[
@description CreateTracksFromText
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-06-08)
  - Initial release
@provides
  [main] Utility/CreateTracksFromText.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags template
@about
  # CreateTracksFromText
  Contextual Create Tracks in Reaper with Name/Parent/children/Spacer and colors by entering a text in form.
  This script was developed with the help of GitHub Copilot.
--]]

local named_colors = {
rouge = {255, 0, 0},
red = {255, 0, 0},
vert = {0, 200, 0},
green = {0, 200, 0},
bleu = {0, 120, 255},
blue = {0, 120, 255},
jaune = {255, 255, 0},
yellow = {255, 255, 0},
violet = {180, 0, 255},
purple = {180, 0, 255},
orange = {255, 140, 0},
rose = {255, 100, 180},
pink = {255, 100, 180},
gris = {120, 120, 120},
grey = {120, 120, 120},
blanc = {255, 255, 255},
white = {255, 255, 255},
noir = {0, 0, 0},
black = {0, 0, 0},
}

local retval, file_path = reaper.GetUserFileNameForRead("", "Sélectionner un fichier texte", ".txt")
if not retval then return end

local file = io.open(file_path, "r")
if not file then
reaper.ShowMessageBox("Impossible d'ouvrir le fichier.", "Erreur", 0)
return
end

local lines = {}
for line in file:lines() do
local indent = line:match("^(%s*)") or ""
local trimmed = line:match("^%s*(.-)%s*$")
table.insert(lines, {raw = line, name = trimmed, indent = #indent})
end
file:close()

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

local function create_track(name, color)
local idx = reaper.CountTracks(0)
reaper.InsertTrackAtIndex(idx, true)
local track = reaper.GetTrack(0, idx)
reaper.GetSetMediaTrackInfo_String(track, "P_NAME", name, true)

if color then
local rgb = named_colors[string.lower(color)]
if rgb then
local col = reaper.ColorToNative(table.unpack(rgb)) | 0x1000000
reaper.SetMediaTrackInfo_Value(track, "I_CUSTOMCOLOR", col)
end
end
return track
end

-- Étape 1 : Créer les pistes et stocker infos
local track_infos = {}
local indent_stack = {}

for _, entry in ipairs(lines) do
local line = entry.name
local indent = entry.indent

if line == "" then
-- Spacer
local idx = reaper.CountTracks(0)
reaper.InsertTrackAtIndex(idx, true)
local t = reaper.GetTrack(0, idx)
reaper.GetSetMediaTrackInfo_String(t, "P_NAME", "", true)
reaper.SetMediaTrackInfo_Value(t, "I_SPACER", 1)
local gray = reaper.ColorToNative(120, 120, 120) | 0x1000000
reaper.SetMediaTrackInfo_Value(t, "I_CUSTOMCOLOR", gray)
else
local name, color = line:match("^(.-)%s*%(([%a]+)%)$")
name = name or line
name = name:match("^%s*(.-)%s*$")
local track = create_track(name, color)

-- Calcul profondeur
while #indent_stack > 0 and indent_stack[#indent_stack].indent >= indent do
table.remove(indent_stack)
end

local depth = #indent_stack
table.insert(indent_stack, {name = name, indent = indent})

table.insert(track_infos, {
name = name,
depth = depth,
track = track
})
end
end

-- Étape 2 : Appliquer I_FOLDERDEPTH
for i, info in ipairs(track_infos) do
local this_depth = info.depth
local next = track_infos[i+1]
local next_depth = next and next.depth or 0

local folder_depth = 0
if next_depth > this_depth then
folder_depth = 1
elseif next_depth < this_depth then
folder_depth = -1 * (this_depth - next_depth)
else
folder_depth = 0
end

reaper.SetMediaTrackInfo_Value(info.track, "I_FOLDERDEPTH", folder_depth)
end

-- Étape 3 : Nettoyage pistes vides non-spacers
for i = reaper.CountTracks(0)-1, 0, -1 do
local t = reaper.GetTrack(0, i)
local _, name = reaper.GetSetMediaTrackInfo_String(t, "P_NAME", "", false)
local isSpacer = reaper.GetMediaTrackInfo_Value(t, "I_SPACER")
if name == "" and isSpacer ~= 1 then
reaper.DeleteTrack(t)
end
end

reaper.PreventUIRefresh(-1)
reaper.TrackList_AdjustWindows(false)
reaper.Undo_EndBlock("Créer pistes (hiérarchie par indentation)", -1)
reaper.UpdateArrange()

reaper.Undo_BeginBlock()
reaper.Main_OnCommand(40297, 0) -- Unselect all tracks

local track_count = reaper.CountTracks(0)
for i = 0, track_count - 1 do
local track = reaper.GetTrack(0, i)
local _, name = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
if name == "" then
reaper.SetTrackSelected(track, true)
end
end

reaper.Undo_EndBlock("Sélectionner pistes sans nom", -1)
reaper.Main_OnCommand(40005, 0)

