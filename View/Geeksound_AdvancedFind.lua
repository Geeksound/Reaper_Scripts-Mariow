--[[
@description AdvancedFind - Advanced Search Tool for Your Sessions
@version 1.1
@author Mariow
@changelog
  v1.1 (2025-11-04)
  - ImGui Windows with credits
  v1.0 (2025-11-01)
  - Integrated Repository-Guide window directly into the script
  - Search for Tracks, Items & Take Markers

@provides
  [main] View/AdvancedFind.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags search, items, takes, markers, tracks, ImGui, multi-selection
@about
  # AdvancedFind
  Search for Tracks, Media Items, Muted Items, and Take Markers in your REAPER project.
  Supports multi-selection with immediate selection in Arrange view.
  Features an integrated ImGui GUI with a thumbnail button to open a Repository Guide (PDF, GitHub, Audio Conforming Guide).
  Requires ReaImGui installed via ReaPack.
  Developed for efficient project navigation and item management.
--]]


 ------------------------------------------
 if not reaper.ImGui_CreateContext then
 reaper.MB("⚠️ ReaImGui is not installed or enabled.\nInstall it via ReaPack.", "Error", 0)
 return
 end
 
 ------------------------------------------
 -- 🧩 ImGui Context
 ------------------------------------------
 local ctx = reaper.ImGui_CreateContext("Advanced Search")
 local font = reaper.ImGui_CreateFont("sans-serif", 14)
 reaper.ImGui_Attach(ctx, font)
 
 ------------------------------------------
 -- 🧠 State Variables
 ------------------------------------------
 local open = true
 local search_text = ''
 local search_results = {}
 local search_results_tkm = {}
 local select_multiple = false
 local selected_mode = 0 -- 0=Take, 1=Track, 2=Muted, 3=Take Markers
 
 ------------------------------------------
 -- 🔍 Search Modes
 ------------------------------------------
 local search_modes = {
 "Take Name",
 "Track Name",
 "Muted Items",
 "Take Markers"
 }
 
 ------------------------------------------
 -- 🖼️ Thumbnail (opens Repository Guide window)
 ------------------------------------------
 local image_path = reaper.GetResourcePath() .. '/Scripts/vignette.png'
 local image = reaper.ImGui_CreateImage(image_path)
 
 ------------------------------------------
 -- 🎨 Repository Guide (gfx window)
 ------------------------------------------
 local function OpenRepositoryGuide()
 local url_pdf = "https://github.com/Geeksound/Reaper_Scripts-Mariow/raw/main/mariow.pdf"
 local url_repo = "https://github.com/Geeksound/Reaper_Scripts-Mariow"
 local url_audio_guide = "https://github.com/Geeksound/Reaper_Scripts-Mariow/blob/main/Documentations/audio_conforming_guide.md"
 local title = "Mariow Guide and Repository"
 local btn1_txt = "📄 Download PDF Repository-Guide"
 local btn2_txt = "🌐 Open Geeksound GitHub"
 local btn3_txt = "🎵 Audio Conforming Guide"
 local was_mouse_down = false
 
 local function CenterWindow(w, h)
 local screen_w, screen_h = 1280, 720
 gfx.init(title, w, h, 0, (screen_w - w)/2, (screen_h - h)/2)
 end
 
 local function DrawButton(x, y, w, h, txt, hover)
 if hover then gfx.set(0.2, 0.7, 1, 1)
 else gfx.set(0.2, 0.6, 0.9, 1) end
 gfx.roundrect(x, y, w, h, 12, 1)
 gfx.setfont(1, "Arial", 18, 'b', 0)
 gfx.set(1,1,1,1)
 local tw = gfx.measurestr(txt)
 gfx.x = x + (w - tw)/2
 gfx.y = y + (h - 20)/2
 gfx.drawstr(txt)
 end
 
 local function GuideLoop()
 gfx.set(0.18, 0.22, 0.34, 1)
 gfx.rect(0, 0, gfx.w, gfx.h, 1)
 
 -- Title
 gfx.set(1, 1, 1, 1)
 gfx.setfont(1, "Arial", 22, 'b', 0)
 local wt = gfx.measurestr(title)
 gfx.x = (gfx.w - wt) / 2
 gfx.y = 32
 gfx.drawstr(title)
 
 -- Buttons
 local btn_w, btn_h = 300, 44
 local spacing = 18
 local btn1_x = (gfx.w - btn_w) / 2
 local btn1_y = gfx.h / 2 - btn_h - spacing
 local btn2_x = btn1_x
 local btn2_y = gfx.h / 2
 local btn3_x = btn1_x
 local btn3_y = gfx.h / 2 + btn_h + spacing
 
 local mx, my = gfx.mouse_x, gfx.mouse_y
 local hover1 = mx > btn1_x and mx < btn1_x + btn_w and my > btn1_y and my < btn1_y + btn_h
 local hover2 = mx > btn2_x and mx < btn2_x + btn_w and my > btn2_y and my < btn2_y + btn_h
 local hover3 = mx > btn3_x and mx < btn3_x + btn_w and my > btn3_y and my < btn3_y + btn_h
 
 DrawButton(btn1_x, btn1_y, btn_w, btn_h, btn1_txt, hover1)
 DrawButton(btn2_x, btn2_y, btn_w, btn_h, btn2_txt, hover2)
 DrawButton(btn3_x, btn3_y, btn_w, btn_h, btn3_txt, hover3)
 
 local mouse_down = gfx.mouse_cap & 1 == 1
 if mouse_down and not was_mouse_down then
 if hover1 then reaper.CF_ShellExecute(url_pdf)
 elseif hover2 then reaper.CF_ShellExecute(url_repo)
 elseif hover3 then reaper.CF_ShellExecute(url_audio_guide)
 end
 end
 was_mouse_down = mouse_down
 
 local info = "(Click a button to open the PDF guide, GitHub repo, or Audio Conforming Guide)"
 gfx.setfont(1, "Arial", 13)
 local wi = gfx.measurestr(info)
 gfx.x = (gfx.w - wi) / 2
 gfx.y = gfx.h - 48
 gfx.set(1,1,1,1)
 gfx.drawstr(info)
 
 if gfx.getchar() >= 0 then reaper.defer(GuideLoop) end
 end
 
 CenterWindow(520, 380)
 GuideLoop()
 end
 
 ------------------------------------------
 -- 🔎 Search Function
 ------------------------------------------
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
 table.insert(search_results, { name = "[Track] " .. trackName, track = track, selected = false })
 else
 goto continue_track
 end
 else
 for j = 0, itemCount - 1 do
 local item = reaper.GetTrackMediaItem(track, j)
 local take = reaper.GetActiveTake(item)
 local isMuted = reaper.GetMediaItemInfo_Value(item, "B_MUTE") == 1
 local include, label = false, ""
 
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
 local label = string.format("Track %d '%s', Item %d: %s", i+1, trackName, j+1, name)
 table.insert(search_results_tkm, { name = label, item = item, tkm_pos = tonumber(pos) })
 end
 end
 end
 end
 end
 end
 end
 end
 
 ------------------------------------------
 -- 🖥️ ImGui Main Interface
 ------------------------------------------
 local function loop()
 local visible
 visible, open = reaper.ImGui_Begin(ctx, "Advanced Search (by Mariow)", open, reaper.ImGui_WindowFlags_AlwaysAutoResize())
 
 if visible then
 -- 🖼️ Centered Thumbnail
 if image then
 local window_width = reaper.ImGui_GetWindowWidth(ctx)
 local img_size = 48
 local cursor_x = (window_width - img_size) / 10
 reaper.ImGui_SetCursorPosX(ctx, cursor_x)
 
 if reaper.ImGui_ImageButton(ctx, 'repo_btn', image, img_size, img_size) then
 OpenRepositoryGuide()
 end
   reaper.ImGui_SameLine(ctx, nil, 20)
 -- Texte "Recherche" en jaune
 reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), reaper.ImGui_ColorConvertDouble4ToU32(1.0, 1.0, 0.0, 1.0))
reaper.ImGui_TextWrapped(ctx,
  "This Script is used to find TRACKS, Items & TakeMarkers.                     " ..
  " << click if YOU are CURIOUS")

 reaper.ImGui_PopStyleColor(ctx)

 else
 reaper.ImGui_Text(ctx, "Image not found: " .. image_path)
 reaper.ImGui_Separator(ctx)
 end
  reaper.ImGui_Separator(ctx)
 -- 🔍 Search UI
 reaper.ImGui_Text(ctx, "Search (Press Return to execute search)")
 local enter_pressed
 enter_pressed, search_text = reaper.ImGui_InputText(ctx, "##search", search_text, reaper.ImGui_InputTextFlags_EnterReturnsTrue())
 
 local changed_mode
 changed_mode, selected_mode = reaper.ImGui_Combo(ctx, "Search Mode", selected_mode, table.concat(search_modes, "\0") .. "\0")
 
 local changed_select_multiple
 changed_select_multiple, select_multiple = reaper.ImGui_Checkbox(ctx, "Multi-selection", select_multiple)
 
 if enter_pressed or changed_mode or changed_select_multiple then
 SearchProjectItems(search_text, selected_mode)
 end
 reaper.ImGui_Separator(ctx)
 
 -- 📋 Results
 local results_list = (selected_mode == 3) and search_results_tkm or search_results
 
 if selected_mode ~= 3 then
 for i, result in ipairs(results_list) do
 if select_multiple then
 local changed
 changed, result.selected = reaper.ImGui_Checkbox(ctx, "##chk_" .. i, result.selected)
 reaper.ImGui_SameLine(ctx)
 reaper.ImGui_Text(ctx, result.name)
 else
 if reaper.ImGui_Selectable(ctx, result.name) then
 reaper.Main_OnCommand(40289, 0)
 reaper.Main_OnCommand(40297, 0)
 if result.track and reaper.ValidatePtr(result.track, "MediaTrack*") then
 reaper.SetTrackSelected(result.track, true)
 reaper.Main_OnCommand(40913, 0)
 elseif result.item and reaper.ValidatePtr(result.item, "MediaItem*") then
 reaper.SetMediaItemSelected(result.item, true)
 reaper.Main_OnCommand(40913, 0)
 end
 reaper.UpdateArrange()
 end
 end
 end
 else
 for i, result in ipairs(results_list) do
 if select_multiple then
 local changed
 changed, result.selected = reaper.ImGui_Checkbox(ctx, "##chk_tkm_" .. i, result.selected)
 reaper.ImGui_SameLine(ctx)
 reaper.ImGui_Text(ctx, result.name)
 else
 if reaper.ImGui_Selectable(ctx, result.name) then
 reaper.Main_OnCommand(40289, 0)
 reaper.SetMediaItemSelected(result.item, true)
 if result.tkm_pos then
 local item_pos = reaper.GetMediaItemInfo_Value(result.item, "D_POSITION")
 local goto_pos = item_pos + result.tkm_pos
 reaper.SetEditCurPos(goto_pos, true, true)
 end
 reaper.UpdateArrange()
 end
 end
 end
 end
 
 -- Multi-selection apply
 if select_multiple and #results_list > 0 then
 reaper.ImGui_Separator(ctx)
 if reaper.ImGui_Button(ctx, "Select Checked Items") then
 reaper.Main_OnCommand(40289, 0)
 for _, result in ipairs(results_list) do
 if result.selected then
 if result.track and reaper.ValidatePtr(result.track, "MediaTrack*") then
 reaper.SetTrackSelected(result.track, true)
 elseif result.item and reaper.ValidatePtr(result.item, "MediaItem*") then
 reaper.SetMediaItemSelected(result.item, true)
 end
 end
 end
 reaper.Main_OnCommand(40913, 0)
 reaper.UpdateArrange()
 end
 end
 
 reaper.ImGui_End(ctx)
 end
 
 if open then
 reaper.defer(loop)
 else
 if reaper.ImGui_DestroyContext then reaper.ImGui_DestroyContext(ctx) end
 end
 end
 
 ------------------------------------------
 -- 🚀 Script Start
 ------------------------------------------
 reaper.defer(loop)

