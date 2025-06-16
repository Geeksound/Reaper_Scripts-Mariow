--[[
@description FieldrecorderTrack-Matching_AUTO-Lite
@version 1.1
@author Mariow
@license MIT
@changelog
  V1.1 (2025-06-16)
  - Add a command to rebuid missing Peaks at the end
  v1.0 (2025-06-08)
  - Initial release
@provides
  [main] Field-Recorder_Workflow/FieldrecorderTrack-Matching_AUTO-Lite.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags dialogue conformation workflow Fieldrecording Track rushs raw files matching conforming
@about
  # FieldrecorderTrack-Matching_AUTO-Lite

  This script comes after AAF importing files (ideally from Vordio).
  This is a light and automatic version of the famous FieldrecorderTrackMatching Script:
  - Searching original files from Fieldrecorder into a folder
  - Importing and placing multichannel poly items below AAF files

  Advanced dialogue Fieldrecorder track matching and organizing like in PROTOOLS.

  This script was developed with the help of GitHub Copilot.
--]]

local r = reaper

if not r.ImGui_CreateContext then
  r.ShowMessageBox("RealMGU (ImGui) isn't installed!", "Error", 0)
  return
end
-- Check items selected
if reaper.CountSelectedMediaItems(0) == 0 then
  reaper.ShowMessageBox("No item selected. Please select at least one item..", "ATTENTION!", 0)
  return
end
-- Initialisation ImGui et police
local ctx = r.ImGui_CreateContext('Metadata Matcher Auto-Mode VERSION')
local BIGFONT = r.ImGui_CreateFont('Comic Sans MS', 30)
local MIDFONT = r.ImGui_CreateFont('Comic Sans MS', 22)
local FONT = r.ImGui_CreateFont('Comic Sans MS', 20)
local BIGBUTTONFONT = r.ImGui_CreateFont('Comic Sans MS', 24)
local ARIALBUTTONFONT = r.ImGui_CreateFont('Arial Bold', 18)
r.ImGui_Attach(ctx, BIGBUTTONFONT)
r.ImGui_Attach(ctx, BIGFONT)
r.ImGui_Attach(ctx, MIDFONT)
r.ImGui_Attach(ctx, FONT)
r.ImGui_Attach(ctx, ARIALBUTTONFONT)


-- Etat fenêtre d'accueil
local show_welcome = true

-- Fonction de la fenêtre d’accueil
local function welcome_window()
  r.ImGui_SetNextWindowSize(ctx, 750, 600, r.ImGui_Cond_Always())
  local visible, open = r.ImGui_Begin(ctx, "Innovative Fieldrecorder for REAPER @Geeksound by mariow", true)
  if visible then
    r.ImGui_PushFont(ctx, BIGFONT)
    if visible then
      r.ImGui_PushFont(ctx, BIGFONT)
      r.ImGui_TextWrapped(ctx,
        "-------------------------------------------------------------------------------- \n" ..
        "Innovative Script inspired by \"The Fieldrecorder Track\" in Protools\n" ..
        "It will allow you to re-link the original files recorded on set\n" ..
        "with the files imported and selected in your AAF session\n\n" ..
        "This an automatic version of \"FieldrecorderTrack-Matching\"\n" ..
        "conceptualized may be efficient in most cases.\n\n" ..
        "The Polyphonic RAW files may be re-linked, and after this\n" ..
        "you may use \"Dial-EditConform\" to:\n" ..
        "explode poly files, auto-rename Items&Tracks by Shooting criterias\n" ..
        "in order to initiate your AUDIO-CONFORMATION properly\n" ..
        "-------------------------------------------------------------------------------- \n\n" ..
        "Best Regards,\n" ..
        "Github.com/Geeksound by Mariow \n" ..
        " "
      )
      r.ImGui_PopFont(ctx)
    end
    r.ImGui_PopFont(ctx)

    r.ImGui_Separator(ctx)

    r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_FramePadding(), 10, 10)
    r.ImGui_PushFont(ctx, BIGBUTTONFONT)
    if r.ImGui_Button(ctx, "--- S T A R T ---", 750, 50) then
      show_welcome = false
    end
    r.ImGui_PopFont(ctx)
    r.ImGui_PopStyleVar(ctx)

    r.ImGui_End(ctx)
  else
    show_welcome = false
  end
end

-- Fonctions utilitaires

local function get_file_metadata(file)
  local src = r.PCM_Source_CreateFromFile(file)
  if not src then return nil end

  local meta = {}
  local tags = {
    { key = "BWF:OriginationDate" }, { key = "IXML:SCENE" },
    { key = "IXML:TAKE" }, { key = "BWF:Description" },
    { key = "IXML:BEXT:BWF_ORIGINATION_DATE" },
    { key = "Generic:StartOffset" }, { key = "Generic:Description" }
  }

  for _, t in ipairs(tags) do
    local retval, value = r.GetMediaFileMetadata(src, t.key)
    if retval and value ~= "" then
      meta[t.key] = value
    end
  end

  r.PCM_Source_Destroy(src)
  return meta
end

local scan_stack, scan_files = {}, {}
local current_item_name = ""
local scanning, launch_matching = false, false
local scan_total_items, selected_folder = 0, ""

local function extract_scene_take(name)
  local scene, take = name:match("([^/]+)/([^%.]+)")
  return scene, take
end

local function match_file(item_name, item_meta, file_meta)
  if not file_meta then return false end

  local scene, take = extract_scene_take(item_name)
  if not scene or not take then return false end

  local meta_scene = file_meta["IXML:SCENE"] or file_meta["BWF:Description"]
  local meta_take = file_meta["IXML:TAKE"] or ""
  if scene ~= meta_scene or take ~= meta_take then return false end

  local item_date = item_meta["BWF:OriginationDate"] or item_meta["IXML:BEXT:BWF_ORIGINATION_DATE"]
  local file_date = file_meta["BWF:OriginationDate"] or file_meta["IXML:BEXT:BWF_ORIGINATION_DATE"]

  if item_date and file_date then
    if item_date ~= file_date then return false end
  else
    local item_offset = item_meta["Generic:StartOffset"]
    local file_offset = file_meta["Generic:StartOffset"]
    if not item_offset or not file_offset or item_offset ~= file_offset then
      return false
    end
  end

  return true
end

local function start_scan(folder)
  scan_stack = { { path = folder, file_index = 0, subdir_index = 0 } }
  scan_files, current_item_name, scan_total_items = {}, "", 0
  scanning = true
end

local function update_scan()
  if #scan_stack == 0 then scanning = false return end
  local sep = r.GetOS():match("Win") and "\\" or "/"
  local current = scan_stack[#scan_stack]
  local folder = current.path

  local file = r.EnumerateFiles(folder, current.file_index)
  if file then
    current_item_name = file
    if file:lower():match("%.wav$") then
      table.insert(scan_files, folder .. sep .. file)
    end
    current.file_index = current.file_index + 1
    scan_total_items = scan_total_items + 1
    return
  end

  local subdir = r.EnumerateSubdirectories(folder, current.subdir_index)
  if subdir then
    table.insert(scan_stack, { path = folder .. sep .. subdir, file_index = 0, subdir_index = 0 })
    current.subdir_index = current.subdir_index + 1
    return
  end

  table.remove(scan_stack)
end

local function rename_selected_items_by_scene_take()
  local sel_cnt = r.CountSelectedMediaItems(0)
  if sel_cnt == 0 then return end

  for i = 0, sel_cnt - 1 do
    local item = r.GetSelectedMediaItem(0, i)
    local take = r.GetActiveTake(item)
    if take then
      local _, notes = r.GetSetMediaItemInfo_String(item, "P_NOTES", "", false)
      local scene_val = notes:match("Scene%s*:%s*(%S+)")
      local take_val = notes:match("Take%s*:%s*(%S+)")
      if scene_val and take_val then
        local new_name = scene_val .. "/" .. take_val
        r.GetSetMediaItemTakeInfo_String(take, "P_NAME", new_name, true)
      end
    end
  end
  r.UpdateArrange()
end

-- Boucle principale
local function loop()
  if show_welcome then
    welcome_window()
  else
    r.ImGui_SetNextWindowSize(ctx, 500, 280, r.ImGui_Cond_FirstUseEver())
    local visible, open = r.ImGui_Begin(ctx, "Metadata Matcher Auto-Mode VERSION", true)

    if visible then
      r.ImGui_PushFont(ctx, FONT)
     r.ImGui_Text(ctx, '" FieldrecorderTrackMatching.lua "  may be required for more accurate searching')
      r.ImGui_PopFont(ctx)

      r.ImGui_Separator(ctx)
      r.ImGui_PushFont(ctx, BIGBUTTONFONT)
      if r.ImGui_Button(ctx, "- dependency & recommendation -") then
        r.CF_ShellExecute("https://github.com/Geeksound/Reaper_Scripts-Mariow/blob/main/PICTURES/metamatcherdependency.png")
      end

      r.ImGui_Separator(ctx)

      if r.ImGui_Button(ctx, "Choose <Folder> with RAW Files") then
        local retval, folder = r.JS_Dialog_BrowseForFolder("Select folder", "")
        if retval ~= 0 then selected_folder = folder end
      end
      r.ImGui_SameLine(ctx)
      r.ImGui_Text(ctx, selected_folder ~= "" and selected_folder or "(No folder selected)")

      r.ImGui_Separator(ctx)

      r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(), 0xFF88CC88)
      r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(), 0xFFAAFFAA)
      r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonActive(), 0xFF55AA55)
      r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_FramePadding(), 10, 10)

      if r.ImGui_Button(ctx, "//                                   SEARCH FILES                                   \\\\") and not scanning then
        if selected_folder ~= "" then
          rename_selected_items_by_scene_take()
          start_scan(selected_folder)
        end
      end
      r.ImGui_PopFont(ctx)

      r.ImGui_PopStyleVar(ctx)
      r.ImGui_PopStyleColor(ctx, 3)

      if scanning then
        local progress = (#scan_files > 0 and scan_total_items > 0) and (#scan_files / scan_total_items) or 0
        if progress > 1 then progress = 1 end

        r.ImGui_OpenPopup(ctx, "Scanning...")

        if r.ImGui_BeginPopupModal(ctx, "Scanning...", nil, r.ImGui_WindowFlags_AlwaysAutoResize()) then
          r.ImGui_Text(ctx, "Please wait for the spinning disk to disappear: scanning folder...")
          r.ImGui_Text(ctx, "Current file: " .. current_item_name)
          r.ImGui_ProgressBar(ctx, progress, 450, 20, "")
          r.ImGui_EndPopup(ctx)
        end
      end

      r.ImGui_End(ctx)
    end

    if not open then
      if r.ImGui_DestroyContext then
        r.ImGui_DestroyContext(ctx)
      end
      return
    end

    if scanning then
      update_scan()
    elseif not scanning and #scan_files > 0 and not launch_matching then
      launch_matching = true
    end

    if launch_matching then
      r.Undo_BeginBlock()
      local item_count = r.CountSelectedMediaItems(0)
      local replaced = 0

      for i = 0, item_count - 1 do
        local item = r.GetSelectedMediaItem(0, i)
        local take = r.GetActiveTake(item)
        if not take then goto continue end

        local src = r.GetMediaItemTake_Source(take)
        local item_path = r.GetMediaSourceFileName(src, "")
        local item_meta = get_file_metadata(item_path)
        local item_name = r.GetTakeName(take)

        for _, file in ipairs(scan_files) do
          local file_meta = get_file_metadata(file)
          if match_file(item_name, item_meta, file_meta) then
            local new_src = r.PCM_Source_CreateFromFile(file)
            if new_src then
              r.SetMediaItemTake_Source(take, new_src)
              replaced = replaced + 1
              break
            end
          end
        end

        ::continue::
      end

      r.Undo_EndBlock("Matching metadata and replacement", -1)
      r.ShowMessageBox("Finished : " .. replaced .. " items replaced !", "End", 0)
      show_launch_popup = true
      launch_matching = false
      scan_files = {}
    end

    -- POPUP de fin : lancement du script suivant
    -- POPUP de fin : lancement du script suivant
    if show_launch_popup then
      r.ImGui_SetNextWindowSize(ctx, 900, 0, r.ImGui_Cond_Appearing())
      r.ImGui_OpenPopup(ctx, "CONFORMATION duty to organize Items&Tracks byName")
    end

    if r.ImGui_BeginPopupModal(ctx, "CONFORMATION duty to organize Items&Tracks byName", nil, r.ImGui_WindowFlags_AlwaysAutoResize()) then
      r.ImGui_PushFont(ctx, BIGFONT)
      r.ImGui_TextWrapped(ctx, "Execute 'Dial-EditConform.lua' \nto explode and organize files ?")
      r.ImGui_PopFont(ctx)
      r.ImGui_Separator(ctx)

      r.ImGui_PushFont(ctx, ARIALBUTTONFONT)
      if r.ImGui_Button(ctx, "yes, do it now", 0, 40) then
        local command_id = "_RS020864c125a69873acc44f20c080d5bc35f26242"
        local command_number = r.NamedCommandLookup(command_id)
        if command_number ~= 0 then
          r.Main_OnCommand(command_number, 0)
        else
          r.ShowMessageBox("Script 'Dial-EditConform.lua' has not been found. Check the installation.", "Error", 0)
        end
        r.ImGui_CloseCurrentPopup(ctx)
        show_launch_popup = false
      end
      r.ImGui_PopFont(ctx)

      r.ImGui_SameLine(ctx)
      r.ImGui_Dummy(ctx, 130, 0) -- Espace horizontal de 15 pixels
      r.ImGui_SameLine(ctx)
      r.ImGui_PushFont(ctx, ARIALBUTTONFONT)
      if r.ImGui_Button(ctx, "No, exit", 0, 40) then
        r.ImGui_CloseCurrentPopup(ctx)
        show_launch_popup = false
      end
      r.ImGui_PopFont(ctx)

      r.ImGui_EndPopup(ctx)
    end
  end

  r.defer(loop)
end

reaper.Main_OnCommand(40047,0) -- Rebuild Missing Peaks

r.defer(loop)
