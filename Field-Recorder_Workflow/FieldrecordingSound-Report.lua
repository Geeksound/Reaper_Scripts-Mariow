--[[
@description Fieldrecording Sound-Report
@version 1.0
@author Mariow
@license MIT
@changelog
  v1.0 (2025-06-17)
  - Initial release
@provides
  [main] Field-Recorder_Workflow/FieldrecordingSound-Reportlua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags dialogue recording conformation workflow Sound-report
@about
  # Fieldrecording Sound-Report
  
  This script comes during Fieldrecording with Reaper
  - Record Production Sound via Dante from Cantar or Scorpio
  - Enter additionals Items notes to describe the Sound recorded
  - Select all Items recorded and launch the Script
  - The Sound Report appear and may be completed
  - Export a CSV version for Post-production
  
  Advanced dialogue track Sound Reporting by reading iXML/BWF metadata, and Items properties.
  
  This script was developed with the help of GitHub Copilot.
--]]

local reaper = reaper
local ctx = reaper.ImGui_CreateContext('Sound-Report')
local font = reaper.ImGui_CreateFont('sans-serif', 16)
reaper.ImGui_Attach(ctx, font)

-- Personnalise ici ton préfixe (laisser vide si non souhaité)
local prefix = ""

-- Champs de l’entête du rapport
local header_fields = {
  Fieldrecorder = "",
  Project = "",
  ["Sound-Mixer Name"] = "",
  Phone = "",
  ["E-Mail"] = ""
}
local header_order = { "Fieldrecorder", "Project", "Sound-Mixer Name", "Phone", "E-Mail" }

-- Largeur personnalisée pour chaque champ d'entête (en pixels)
local header_widths = {
  Fieldrecorder = 140,
  Project = 340,
  ["Sound-Mixer Name"] = 220,
  Phone = 120,
  ["E-Mail"] = 280
}

-- Largeur personnalisée pour les colonnes du tableau principal
local table_column_widths = {
  CIRCLED = 56 -- Par exemple : la colonne "CIRCLED" fait 56 pixels
  -- ajoute d'autres colonnes ici si besoin, ex : NOTE = 90
}

-- Largeur de l’espace (en pixels) entre chaque colonne
local spacer_width = 2

-- Les clés fixes AVANT les tracks
local pre_track_keys = {"FILENAME", "TAPE", "Date", "Time", "SCENE", "TAKE"}
-- Les clés fixes APRES les tracks (CIRCLED tout à la fin)
local post_track_keys = {"NOTE", "ITEMNOTES", "CIRCLED"}

local all_keys = {}
local selected_keys = {}

local metadata_table = {}

local function get_filename_noext(path)
  return path:match("([^/\\]+)%.%w+$") or path
end

local function safe_get_metadata(src, ...)
  for i = 1, select("#", ...) do
    local tag = select(i, ...)
    local ok, val = reaper.GetMediaFileMetadata(src, tag)
    if ok and val ~= "" then return val end
  end
  return ""
end

function get_metadata()
  metadata_table = {}
  local num_items = reaper.CountSelectedMediaItems(0)
  local max_tracks = 0
  local temp_entries = {}

  for i = 0, num_items - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    local take = reaper.GetActiveTake(item)
    if take and not reaper.TakeIsMIDI(take) then
      local source = reaper.GetMediaItemTake_Source(take)
      local filename_full = reaper.GetMediaSourceFileName(source, "")
      local filename = get_filename_noext(filename_full)
      local filename_display = prefix .. filename

      local tape = safe_get_metadata(source, "IXML:TAPE", "aTAPE")
      local date = safe_get_metadata(source, "BWF:OriginationDate")
      local time = safe_get_metadata(source, "BWF:OriginationTime")
      local scene = safe_get_metadata(source, "IXML:SCENE", "aSCENE")
      local take_nb = safe_get_metadata(source, "IXML:TAKE", "aTAKE")
      local circled_val = safe_get_metadata(source, "IXML:CIRCLED", "aCIRCLED")
      local note = safe_get_metadata(source, "IXML:NOTE", "aNOTE")

      -- CIRCLED : affiche X si YES, sinon NO
      local circled = (circled_val == "YES") and "X" or "NO"

      local scene_display = prefix .. (scene or "")
      local take_display = prefix .. (take_nb or "")
      local note_display = prefix .. (note or "")

      -- ItemNotes (notes d’item REAPER)
      local item_notes = ""
      local retval, notes = reaper.GetSetMediaItemInfo_String(item, "P_NOTES", "", false)
      if retval then item_notes = notes end

      local track_count = tonumber(safe_get_metadata(source, "IXML:TRACK_LIST:TRACK_COUNT")) or 0
      if track_count > max_tracks then max_tracks = track_count end

      local tracks = {}
      for trk = 1, track_count do
        local name_tag = (trk == 1) and "IXML:TRACK_LIST:TRACK:NAME" or ("IXML:TRACK_LIST:TRACK:NAME:" .. trk)
        local trk_name = safe_get_metadata(source, name_tag)
        tracks[trk] = prefix .. (trk_name or "")
      end

      table.insert(temp_entries, {
        FILENAME = filename_display,
        TAPE = tape,
        ["Date"] = date,
        ["Time"] = time,
        SCENE = scene_display,
        TAKE = take_display,
        NOTE = note_display,
        ITEMNOTES = item_notes,
        CIRCLED = circled,
        TRACKS = tracks,
        TRACK_COUNT = track_count
      })
    end
  end

  all_keys = {}
  for _, k in ipairs(pre_track_keys) do table.insert(all_keys, k) end
  for i = 1, max_tracks do table.insert(all_keys, "TRACK"..i) end
  for _, k in ipairs(post_track_keys) do table.insert(all_keys, k) end

  for _, k in ipairs(all_keys) do selected_keys[k] = true end

  for _, entry in ipairs(temp_entries) do
    local row = {}
    for _, key in ipairs(pre_track_keys) do row[key] = entry[key] end
    for i = 1, max_tracks do
      row["TRACK"..i] = entry.TRACKS[i] or ""
    end
    for _, key in ipairs(post_track_keys) do row[key] = entry[key] end
    table.insert(metadata_table, row)
  end
end

function export_csv()
  local default_path = reaper.GetProjectPath("").."/metadata_export.csv"
  local ok, user_path = reaper.GetUserInputs("Exporter CSV", 1, "Chemin complet du fichier CSV :", default_path)
  if not ok or not user_path or user_path == "" then return end

  local file = io.open(user_path, "w")
  if not file then
    reaper.ShowMessageBox("Erreur : impossible d'écrire le fichier.", "Erreur", 0)
    return
  end

  -- Ligne d'en-tête personnalisée à remplir
  file:write(table.concat(header_order, ",") .. "\n")
  local header_vals = {}
  for _, k in ipairs(header_order) do
    table.insert(header_vals, (header_fields[k] or ""))
  end
  file:write(table.concat(header_vals, ",") .. "\n")

  -- Ligne vide pour séparer
  file:write("\n")

  -- En-têtes des données
  local headers = {}
  for i, key in ipairs(all_keys) do
    if selected_keys[key] then
      table.insert(headers, key)
    end
  end
  file:write(table.concat(headers, ",") .. "\n")

  -- Lignes de données
  for _, entry in ipairs(metadata_table) do
    local row = {}
    for i, key in ipairs(all_keys) do
      if selected_keys[key] then
        local val = entry[key] or ""
        val = '"' .. tostring(val):gsub('"', '""') .. '"'
        table.insert(row, val)
      end
    end
    file:write(table.concat(row, ",") .. "\n")
  end

  file:close()
  reaper.ShowMessageBox("Fichier CSV exporté :\n" .. user_path, "Succès", 0)
end

function loop()
  local visible, open = reaper.ImGui_Begin(ctx, 'Sound-Report', true, reaper.ImGui_WindowFlags_MenuBar())
  if visible then
    -- Affichage des champs entête sur une seule ligne, largeurs personnalisées
    reaper.ImGui_Separator(ctx)
    reaper.ImGui_Text(ctx, "Sound-Report Datas :")
    if reaper.ImGui_BeginTable(ctx, "HeaderFields", #header_order, reaper.ImGui_TableFlags_Borders()) then
      reaper.ImGui_TableNextRow(ctx)
      -- En-têtes
      for col, k in ipairs(header_order) do
        reaper.ImGui_TableSetColumnIndex(ctx, col - 1)
        reaper.ImGui_Text(ctx, k)
      end
      reaper.ImGui_TableNextRow(ctx)
      -- Saisie sur une ligne, largeurs personnalisées
      for col, k in ipairs(header_order) do
        reaper.ImGui_TableSetColumnIndex(ctx, col - 1)
        if header_widths[k] then
          reaper.ImGui_SetNextItemWidth(ctx, header_widths[k])
        end
        local retval, new_val = reaper.ImGui_InputText(ctx, "##"..k, header_fields[k], 256)
        if retval then header_fields[k] = new_val end
      end
      reaper.ImGui_EndTable(ctx)
    end
    reaper.ImGui_Separator(ctx)
    reaper.ImGui_Spacing(ctx)

    -- Menu de sélection des colonnes
    if reaper.ImGui_BeginMenuBar(ctx) then
      if reaper.ImGui_BeginMenu(ctx, " ") then
        for _, key in ipairs(all_keys) do
          local v = selected_keys[key] or false
          local changed, newval = reaper.ImGui_MenuItem(ctx, key, nil, v)
          if changed then selected_keys[key] = newval end
        end
        reaper.ImGui_EndMenu(ctx)
      end
      reaper.ImGui_EndMenuBar(ctx)
    end

    if reaper.ImGui_Button(ctx, "Refresh") then
      get_metadata()
    end
    reaper.ImGui_SameLine(ctx)
    if reaper.ImGui_Button(ctx, "Export CSV") then
      export_csv()
    end

    -- Colonnes espacées : on insère une colonne vide entre chaque colonne de données
    -- Construction de la liste des colonnes (avec espace entre chaque)
    local all_keys_with_spacers = {}
    for i, k in ipairs(all_keys) do
      table.insert(all_keys_with_spacers, k)
      if i < #all_keys then
        table.insert(all_keys_with_spacers, "__SPACER__")
      end
    end

    -- Calcul du nombre total de colonnes à afficher
    local col_count = 0
    for _, key in ipairs(all_keys_with_spacers) do
      if key == "__SPACER__" or selected_keys[key] then
        col_count = col_count + 1
      end
    end

    local flags = reaper.ImGui_TableFlags_Borders() | reaper.ImGui_TableFlags_SizingFixedFit()
    if col_count > 0 and reaper.ImGui_BeginTable(ctx, 'MetadataTable', col_count, flags) then
      for _, key in ipairs(all_keys_with_spacers) do
        if key == "__SPACER__" then
          reaper.ImGui_TableSetupColumn(ctx, "", nil, spacer_width)
        elseif selected_keys[key] then
          local width = table_column_widths[key]
          reaper.ImGui_TableSetupColumn(ctx, key, nil, width)
        end
      end
      reaper.ImGui_TableHeadersRow(ctx)

      for _, entry in ipairs(metadata_table) do
        reaper.ImGui_TableNextRow(ctx)
        local col = 0
        for _, key in ipairs(all_keys_with_spacers) do
          reaper.ImGui_TableSetColumnIndex(ctx, col)
          if key == "__SPACER__" then
            reaper.ImGui_Text(ctx, "")
          elseif selected_keys[key] then
            reaper.ImGui_Text(ctx, tostring(entry[key] or ""))
          end
          col = col + 1
        end
      end

      reaper.ImGui_EndTable(ctx)
    end

    reaper.ImGui_End(ctx)
  end

  if open then
    reaper.defer(loop)
  end
end

get_metadata()
reaper.defer(loop)
