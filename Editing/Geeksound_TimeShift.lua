--[[
@description TimeShift
@version 1.4.2.1
@author Mariow
@changelog
  v1.4.2.1 (2025-11-04)
  - Imgui windows with credits
  v1.4.2 (2025-10-30)
  - Added help tooltips on Selected Item, Time Selection, and Cursor Position
  - Added fallback for ImGui_TextUnformatted to ensure backward compatibility

  v1.4 (2025-10-30)
  - ImGui interface optimization

  v1.3 (2025-06-08)
  - English version V2

  v1.2 (2025-04-20)
  - Added multi-item handling improvements
  - Fixed cursor shift issue when no time selection

  v1.1 (2025-03-02)
  - Improved UI feedback and responsiveness
  - Added tooltip hints for parameters

  v1.0 (2025-02-10)
  - Initial release

@provides
  [main] Editing/TimeShift.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags timecode, display, items, editing
@about
  # TimeShift
  Contextual edit/SHIFT for Items, Time Selection, and Cursor Position in Reaper 7.0.
  This script provides precise contextual shifting capabilities using ImGui for real-time feedback and control.
  Developed with the help of GitHub Copilot.
--]]


--========================================
-- ReaImGui: Time Converter (samples -> hh:mm:ss:ff)
--========================================
local ctx = reaper.ImGui_CreateContext('TimeShift Like in Protools and better')

------------Fonts for interface
local font_normal = reaper.ImGui_CreateFont('Arial')
local font_bold   = reaper.ImGui_CreateFont('Arial Bold')
reaper.ImGui_Attach(ctx, font_normal)
reaper.ImGui_Attach(ctx, font_bold)

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
local Texte1 = "This option shifts the selected media items along the timeline."
local Texte2 = "This option moves the active time selection."
local Texte3 = "This option shifts the current edit cursor position."

--========================================
-- 🔹 GitHub Thumbnail
--========================================
local github_link = "https://github.com/Geeksound/Reaper_Scripts-Mariow"
-- 🔹 GitHub Thumbnail (optional image)
local vignette_path = reaper.GetResourcePath() .. '/Scripts/vignette.png'
local vignette_image = nil
if reaper.file_exists and reaper.file_exists(vignette_path) then
    vignette_image = reaper.ImGui_CreateImage(vignette_path)
end


local function open_github_link()
    if reaper.CF_ShellExecute then
        reaper.CF_ShellExecute(github_link)
    else
        reaper.ShowMessageBox("⚠️ Unable to open the link.\nSWS extension is required.", "Error", 0)
    end
end

--========================================
-- Constants and Utility Functions
--========================================
local project_sr = reaper.GetSetProjectInfo(0, 'PROJECT_SRATE', 0, false)
local fps = 25 -- Framerate for timecode

-- Convert samples to timecode string
local function format_timecode(samples, sample_rate, fps)
    local total_seconds = samples / sample_rate
    local hours = math.floor(total_seconds / 3600)
    local minutes = math.floor((total_seconds % 3600) / 60)
    local seconds = math.floor(total_seconds % 60)
    local frames = math.floor((total_seconds - math.floor(total_seconds)) * fps + 0.5)
    return string.format("%02d:%02d:%02d:%02d", hours, minutes, seconds, frames)
end

-- Core values
local sample_pos = math.floor(project_sr)
local timecode_str = { format_timecode(sample_pos, project_sr, fps) }
local milliseconds_val = { math.floor((sample_pos / project_sr) * 1000 + 0.5) }
local samples_val = { sample_pos }
local direction = "Forward"
local target = "Item"

-- Parse timecode string to samples
local function parse_timecode_to_samples(tc)
    local h, m, s, f = tc:match("(%d+):(%d+):(%d+):(%d+)")
    if h and m and s and f then
        local total_seconds = tonumber(h)*3600 + tonumber(m)*60 + tonumber(s) + tonumber(f)/fps
        return math.floor(total_seconds * project_sr + 0.5)
    end
end

-- Update all linked fields based on current sample position
local function update_fields_from_samples()
    local sec = sample_pos / project_sr
    timecode_str[1] = format_timecode(sample_pos, project_sr, fps)
    milliseconds_val[1] = math.floor(sec * 1000 + 0.5)
    samples_val[1] = sample_pos
end

-- Apply the time shift
local function apply_shift()
    local delta_sec = sample_pos / project_sr
    if direction == "Backward" then delta_sec = -delta_sec end
    reaper.Undo_BeginBlock()

    if target == "Item" then
        for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
            local item = reaper.GetSelectedMediaItem(0, i)
            if item then
                local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
                reaper.SetMediaItemInfo_Value(item, "D_POSITION", pos + delta_sec)
            end
        end
    elseif target == "Time Selection" then
        local start_time, end_time = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
        if end_time > start_time then
            reaper.GetSet_LoopTimeRange(true, false, start_time + delta_sec, end_time + delta_sec, false)
        else
            reaper.ShowMessageBox("No active time selection", "Error", 0)
        end
    elseif target == "CursorPos" then
        local cur_pos = reaper.GetCursorPosition()
        reaper.SetEditCurPos(cur_pos + delta_sec, true, false)
    end

    reaper.Undo_EndBlock("Time Shift", -1)
    reaper.UpdateArrange()
end

--========================================
-- ImGui Main Loop
--========================================
local function loop()
    local visible, open = reaper.ImGui_Begin(ctx, 'TimeShift Like in Protools and better (by Mariow)', true, reaper.ImGui_WindowFlags_AlwaysAutoResize())

    if visible then
        -- Input fields
        local changed_tc, new_tc = reaper.ImGui_InputText(ctx, 'Timecode (hh:mm:ss:ff)', timecode_str[1], 256)
        if changed_tc then local s = parse_timecode_to_samples(new_tc); if s then sample_pos = s; update_fields_from_samples() end end

        local changed_ms, new_ms = reaper.ImGui_InputInt(ctx, 'Milliseconds', milliseconds_val[1])
        if changed_ms then sample_pos = math.floor((new_ms / 1000) * project_sr + 0.5); update_fields_from_samples() end

        local changed_samples, new_samples = reaper.ImGui_InputInt(ctx, 'Samples', samples_val[1])
        if changed_samples then sample_pos = new_samples; update_fields_from_samples() end

        reaper.ImGui_Text(ctx, " ")
        reaper.ImGui_Separator(ctx)

        -- Shift direction section
        if reaper.ImGui_RadioButton(ctx, 'Backward', direction == "Backward") then direction = "Backward" end
        reaper.ImGui_SameLine(ctx)
        if reaper.ImGui_RadioButton(ctx, 'Forward', direction == "Forward") then direction = "Forward" end

        reaper.ImGui_SameLine(ctx, nil, 30)
        if vignette_image then
           -- ✅ Si la vignette existe, on affiche le bouton image
          if reaper.ImGui_ImageButton(ctx, 'vignette_github_btn', vignette_image, 24, 24) then
            open_github_link()
          end
        else
        -- 🚨 Si la vignette est absente, on affiche un bouton "Open"
          if reaper.ImGui_Button(ctx, "Open", 50, 24) then
            open_github_link()
           end
        end


        reaper.ImGui_SameLine(ctx)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), reaper.ImGui_ColorConvertDouble4ToU32(1,1,0,1))
        reaper.ImGui_PushFont(ctx, font_bold, 14)
        reaper.ImGui_Text(ctx, "Visit my GitHub")
        reaper.ImGui_PopFont(ctx)
        reaper.ImGui_PopStyleColor(ctx)

        reaper.ImGui_Separator(ctx)

        -- 🔹 Targets + Help Tooltips
        if reaper.ImGui_RadioButton(ctx, 'Selected Item', target == "Item") then target = "Item" end
        ImGui_HelpMarker(ctx, Texte1)
        reaper.ImGui_SameLine(ctx)
        if reaper.ImGui_RadioButton(ctx, 'Time Selection', target == "Time Selection") then target = "Time Selection" end
        ImGui_HelpMarker(ctx, Texte2)
        reaper.ImGui_SameLine(ctx)
        if reaper.ImGui_RadioButton(ctx, 'Cursor Position', target == "CursorPos") then target = "CursorPos" end
        ImGui_HelpMarker(ctx, Texte3)

        reaper.ImGui_Separator(ctx)

        -- Apply button
        reaper.ImGui_PushFont(ctx, font_bold, 16)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0xFFAA00FF)
        if reaper.ImGui_Button(ctx, 'Apply Shift', -1) then apply_shift() end
        reaper.ImGui_PopStyleColor(ctx)
        reaper.ImGui_PopFont(ctx)

        reaper.ImGui_End(ctx)
    end

    if open then
        reaper.defer(loop)
    else
        if reaper.ImGui_DestroyContext then reaper.ImGui_DestroyContext(ctx) end
    end
end

reaper.defer(loop)

