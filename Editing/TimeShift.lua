--[[
@description TimeShift
@version 1.3
@author Mariow
@changelog
  v1.3 (2025-06-08)
  - English version V2
@provides
  [main] Editing/TimeShift.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags timecode, display, items, editing
@about
  # TimeShift
  Contextual edit/SHIFT for Items, Time Selection, and Cursor Position in Reaper 7.0.
  This script was developed with the help of GitHub Copilot.
--]]

-- ReaImGui: Time Converter (samples -> hh:mm:ss:ff)
local ctx = reaper.ImGui_CreateContext('Time Converter')

-- Constants
local project_sr = reaper.GetSetProjectInfo(0, 'PROJECT_SRATE', 0, false)
local fps = 25 -- Framerate for the timecode

-- Helper: Format timecode (samples -> hh:mm:ss:ff)
local function format_timecode(samples, sample_rate, fps)
    local total_seconds = samples / sample_rate
    local hours = math.floor(total_seconds / 3600)
    local minutes = math.floor((total_seconds % 3600) / 60)
    local seconds = math.floor(total_seconds % 60)
    local frames = math.floor((total_seconds - math.floor(total_seconds)) * fps + 0.5)
    return string.format("%02d:%02d:%02d:%02d", hours, minutes, seconds, frames)
end

-- Central value
local sample_pos = math.floor(project_sr) -- Default to 1 second

-- Display fields
local timecode_str = { format_timecode(sample_pos, project_sr, fps) }
local milliseconds_val = { math.floor((sample_pos / project_sr) * 1000 + 0.5) }
local samples_val = { sample_pos }

local direction = "Forward"
local target = "Item"

-- Helper: Parse timecode (hh:mm:ss:ff -> samples)
local function parse_timecode_to_samples(tc)
    local h, m, s, f = tc:match("(%d+):(%d+):(%d+):(%d+)")
    if h and m and s and f then
        local total_seconds = tonumber(h) * 3600 + tonumber(m) * 60 + tonumber(s) + tonumber(f) / fps
        return math.floor(total_seconds * project_sr + 0.5)
    else
        return nil
    end
end

-- Update display fields based on central value (samples)
local function update_fields_from_samples()
    local sec = sample_pos / project_sr
    timecode_str[1] = format_timecode(sample_pos, project_sr, fps)
    milliseconds_val[1] = math.floor(sec * 1000 + 0.5)
    samples_val[1] = sample_pos
end

-- Apply time shift
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

-- ImGui Loop
local function loop()
    local visible, open = reaper.ImGui_Begin(ctx, 'Time Converter (samples)', true, reaper.ImGui_WindowFlags_AlwaysAutoResize())

    if visible then
        -- Timecode Input
        local changed_tc, new_tc = reaper.ImGui_InputText(ctx, 'Timecode (hh:mm:ss:ff)', timecode_str[1], 256)
        if changed_tc then
            local s = parse_timecode_to_samples(new_tc)
            if s then
                sample_pos = s
                update_fields_from_samples()
            end
        end

        -- Milliseconds Input
        local changed_ms, new_ms = reaper.ImGui_InputInt(ctx, 'Milliseconds', milliseconds_val[1])
        if changed_ms then
            sample_pos = math.floor((new_ms / 1000) * project_sr + 0.5)
            update_fields_from_samples()
        end

        -- Samples Input
        local changed_samples, new_samples = reaper.ImGui_InputInt(ctx, 'Samples', samples_val[1])
        if changed_samples then
            sample_pos = new_samples
            update_fields_from_samples()
        end

        -- Shift Options
        reaper.ImGui_Separator(ctx)
        reaper.ImGui_Text(ctx, "Shift Direction")
        
        if reaper.ImGui_RadioButton(ctx, 'Backward', direction == "Backward") then direction = "Backward" end
        reaper.ImGui_SameLine(ctx)
        if reaper.ImGui_RadioButton(ctx, 'Forward', direction == "Forward") then direction = "Forward" end

        reaper.ImGui_Separator(ctx)
        reaper.ImGui_Text(ctx, "Target")
        
        if reaper.ImGui_RadioButton(ctx, 'Selected Item', target == "Item") then target = "Item" end
        reaper.ImGui_SameLine(ctx)
        if reaper.ImGui_RadioButton(ctx, 'Time Selection', target == "Time Selection") then target = "Time Selection" end
        reaper.ImGui_SameLine(ctx)
        if reaper.ImGui_RadioButton(ctx, 'Cursor Position', target == "CursorPos") then target = "CursorPos" end

        reaper.ImGui_Separator(ctx)
        if reaper.ImGui_Button(ctx, 'Apply Shift', -1) then
            apply_shift()
        end

        reaper.ImGui_End(ctx)
    end

    if open then
        reaper.defer(loop)
    else
        if reaper.ImGui_DestroyContext then
            reaper.ImGui_DestroyContext(ctx)
        end
    end
end

reaper.defer(loop)
