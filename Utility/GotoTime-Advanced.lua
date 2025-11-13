--[[
@description GoTo Time/Markers 
@version 1.1
@author Mariow
@changelog
  v1.1 (2025-11-13)
  -"Go Marker" button
  - Pressing Return/Enter in the Marker input field jumps directly to that marker
  v1.0 (2025-11-05)
  - Translated all text and comments to English
  - Cleaned up ImGui layout (aligned labels, compact offset slider)
  - Improved header to ReaPack format
@provides
  [main] Utility/GotoTime-Advanced.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags time, navigation, utility, ImGui
@about
  # GotoTime + GoToMarker
  ImGui-based time navigator for REAPER (25fps).  
  Includes:
  - Large centered time counter
  - Sliders for H:M:S:F, Go/Play buttons, presets, offset control  
  - Current cursor display & time selection option  
  - Go To Marker by number or name (press Enter)
--]]

local reaper = reaper
local ctx = reaper.ImGui_CreateContext('Go To Time @25fps')
local fps = 25
local frame_duration = 1 / fps

-- 🧱 Load a larger font for the main counter
local font_big = reaper.ImGui_CreateFont('sans-serif', 32)
reaper.ImGui_Attach(ctx, font_big)

-- Restore previous values if available
local function get_ext(name, default)
    return tonumber(reaper.GetExtState('GoToTime', name)) or default
end

local hour   = get_ext('hour', 0)
local minute = get_ext('minute', 0)
local second = get_ext('second', 0)
local frame  = get_ext('frame', 0)
local offset = get_ext('offset', 0)
local create_time_sel = false
local marker_input = ""

-- Save persistent state
local function save_state()
    reaper.SetExtState('GoToTime', 'hour', tostring(hour), false)
    reaper.SetExtState('GoToTime', 'minute', tostring(minute), false)
    reaper.SetExtState('GoToTime', 'second', tostring(second), false)
    reaper.SetExtState('GoToTime', 'frame', tostring(frame), false)
    reaper.SetExtState('GoToTime', 'offset', tostring(offset), false)
end

-- Convert H:M:S:F → seconds
local function time_to_seconds(h, m, s, f)
    return (h * 3600) + (m * 60) + s + (f * frame_duration)
end

-- Go to marker by number or name
local function go_to_marker(input)
    if input == "" then return end
    local a = tonumber(input)
    if a ~= nil then
        reaper.GoToMarker(reaper.GetCurrentProjectInLoadSave(), a, false)
    else
        local i = 0
        while true do
            local ret, isrgn, pos, rgnend, name, markid = reaper.EnumProjectMarkers(i)
            if ret == 0 then break end
            if name == input then
                reaper.GoToMarker(reaper.GetCurrentProjectInLoadSave(), markid, false)
                return
            end
            i = i + 1
        end
        reaper.ShowMessageBox("Marker not found: " .. input, "Go To Marker", 0)
    end
end

-- Main GUI loop
local function loop()
    if not ctx then return end

    reaper.ImGui_SetNextWindowSize(ctx, 450, 380, reaper.ImGui_Cond_FirstUseEver())
    local visible, open = reaper.ImGui_Begin(ctx, 'Go To Time (25fps) + Marker  by Mariow', true)

    if visible then
        -----------------------------------------
        -- DISPLAY: Big centered counter
        -----------------------------------------
        local base_time = time_to_seconds(hour, minute, second, frame)
        local display_time = math.max(0, base_time - offset)
        local disp_hour = math.floor(display_time / 3600)
        local disp_min  = math.floor((display_time % 3600) / 60)
        local disp_sec  = math.floor(display_time % 60)
        local disp_frame = math.floor((display_time - math.floor(display_time)) / frame_duration + 0.5)
        local display_str = string.format("%02d:%02d:%02d:%02d", disp_hour, disp_min, disp_sec, disp_frame)

        local window_width = reaper.ImGui_GetWindowWidth(ctx)
        reaper.ImGui_PushFont(ctx, font_big,20)
        local text_width = reaper.ImGui_CalcTextSize(ctx, display_str)
        reaper.ImGui_SetCursorPosX(ctx, (window_width - text_width) * 0.5)
        reaper.ImGui_TextColored(ctx, 0xFFCC33FF, display_str)
        reaper.ImGui_PopFont(ctx)

        -----------------------------------------
        -- Current Time Position
        -----------------------------------------
        local cur_pos = reaper.GetCursorPosition()
        local cur_hour = math.floor(cur_pos / 3600)
        local cur_min  = math.floor((cur_pos % 3600) / 60)
        local cur_sec  = math.floor(cur_pos % 60)
        local cur_frame = math.floor((cur_pos - math.floor(cur_pos)) / frame_duration + 0.5)
        local cur_str = string.format("%02d:%02d:%02d:%02d", cur_hour, cur_min, cur_sec, cur_frame)

        reaper.ImGui_Separator(ctx)
        reaper.ImGui_Text(ctx, "Current Time Position:")
        reaper.ImGui_SameLine(ctx, nil, 5)
        reaper.ImGui_TextColored(ctx, 0x66CCFFFF, cur_str)

        reaper.ImGui_SameLine(ctx, nil, 50)
        local changed_checkbox
        changed_checkbox, create_time_sel = reaper.ImGui_Checkbox(ctx, "Make Time Selection", create_time_sel)
        reaper.ImGui_Separator(ctx)

        -----------------------------------------
        -- Sliders: Hours / Minutes / Seconds / Frames
        -----------------------------------------
        local changed = false
        local ch
        ch, hour   = reaper.ImGui_SliderInt(ctx, "Hours", hour, 0, 23); changed = changed or ch
        ch, minute = reaper.ImGui_SliderInt(ctx, "Minutes", minute, 0, 59); changed = changed or ch
        ch, second = reaper.ImGui_SliderInt(ctx, "Seconds", second, 0, 59); changed = changed or ch
        ch, frame  = reaper.ImGui_SliderInt(ctx, "Frames (25fps)", frame, 0, fps - 1); changed = changed or ch

        -----------------------------------------
        -- Buttons: Go / Play
        -----------------------------------------
        reaper.ImGui_Separator(ctx)
        if reaper.ImGui_Button(ctx, "Go", 100, 32) then
            local time = math.max(0, base_time - offset)
            reaper.SetEditCurPos(time, true, false)
            save_state()
            local msg = string.format("Moved to %s (Offset: %ds)", display_str, offset)
            local mx, my = reaper.GetMousePosition()
            reaper.TrackCtl_SetToolTip(msg, mx, my, true)
            if create_time_sel then
                reaper.GetSet_LoopTimeRange(true, false, cur_pos, time, false)
            end
        end
        
        reaper.ImGui_SameLine(ctx,nil,30)
        -----------------------------------------
        -- NEW: Go To Marker (auto on Return)
        -----------------------------------------
        reaper.ImGui_Text(ctx, "Go To Marker\n(Press Enter):")
        reaper.ImGui_SetNextItemWidth(ctx, 40)
        reaper.ImGui_SameLine(ctx)
        local changed_marker, marker_input_entered = reaper.ImGui_InputText(ctx, "##MarkerInput", marker_input, reaper.ImGui_InputTextFlags_EnterReturnsTrue())
        if changed_marker then marker_input = marker_input_entered end
        if reaper.ImGui_IsItemDeactivatedAfterEdit(ctx) then
            go_to_marker(marker_input)
        end
        reaper.ImGui_SameLine(ctx)
        if reaper.ImGui_Button(ctx, "Play", 100, 32) then
            reaper.OnPlayButton()
        end
        

        -----------------------------------------
        -- Presets
        -----------------------------------------
        reaper.ImGui_Separator(ctx)
        reaper.ImGui_Text(ctx, "Presets:")
        if reaper.ImGui_Button(ctx, "1h", 80, 28) then hour, minute, second, frame = 1,0,0,0; save_state() end
        reaper.ImGui_SameLine(ctx)
        if reaper.ImGui_Button(ctx, "10h", 80, 28) then hour, minute, second, frame = 10,0,0,0; save_state() end

        -----------------------------------------
        -- Offset
        -----------------------------------------
        reaper.ImGui_SameLine(ctx)
        reaper.ImGui_TextColored(ctx, 0xFFFF00FF, "Offset (s):")
        reaper.ImGui_SameLine(ctx, nil, 10)
        reaper.ImGui_SetNextItemWidth(ctx, 120)
        local changed_offset
        changed_offset, offset = reaper.ImGui_SliderInt(ctx, "##Offset", offset, 0, 30, "%d s")
        if changed_offset then reaper.SetExtState('GoToTime', 'offset', tostring(offset), false) end


        if changed then save_state() end
        reaper.ImGui_End(ctx)
    end

    if open then reaper.defer(loop) end
end

loop()

