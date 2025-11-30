--[[
@description Interactive-TC-Display
@version 1.3.1
@author Mariow
@license MIT
@changelog

  V1.3.1 (2025-11-29)
  - No Tittle in Popup Window
  V1.3 (2025-11-13)
  - Added "Go To Marker" input field under cursor position display
  V1.2.1 (2025-11-04)
  - Add credits in ImGui Window
  V1.2 (2025-09-08)
  - ReaImguiV0.10.02 Font Compatibility
  v1.0 (2025-06-08)
  - Initial release
@provides
  [main] View/Interactive-TC-Display.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags timecode display reaper contextual items status marker navigation
@about
  # Interactive-TC-Display

  Contextual display of TimeCode / Items / Status for Reaper 7.0.
  Added Go To Marker feature (type a marker number or name and press Enter).
--]]

---------------------------------------------
-- ImGui + Fonts setup
---------------------------------------------
local ctx = reaper.ImGui_CreateContext('Interactive-TC-Display')
local FONT_SIZE = 24 
local BIG_FONT_SIZE = 40
local SMALL_FONT_SIZE = 16
local MID_FONT_SIZE = 34
local font_main = reaper.ImGui_CreateFont('Comic Sans MS')
local font_big = reaper.ImGui_CreateFont('Arial')
local font_small = reaper.ImGui_CreateFont('Comic')
local font_mid = reaper.ImGui_CreateFont('Arial')

reaper.ImGui_Attach(ctx, font_main)
reaper.ImGui_Attach(ctx, font_big)
reaper.ImGui_Attach(ctx, font_small)
reaper.ImGui_Attach(ctx, font_mid)

---------------------------------------------
-- Variables
---------------------------------------------
local recording_start_time = nil
local marker_input = ""

---------------------------------------------
-- Utility functions
---------------------------------------------
local function format_timecode(pos)
    local fps = reaper.TimeMap_curFrameRate(0)
    local total_frames = math.floor(pos * fps + 0.5)
    local frames = total_frames % math.floor(fps)
    local seconds_total = math.floor(total_frames / fps)
    local seconds = seconds_total % 60
    local minutes = math.floor(seconds_total / 60) % 60
    local hours = math.floor(seconds_total / 3600)
    return string.format("%02d:%02d:%02d:%02d", hours, minutes, seconds, frames)
end

local function remove_extension(name)
    return name:match("(.+)%.[^%.]+$") or name
end

---------------------------------------------
-- NEW: Go To Marker function
---------------------------------------------
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

---------------------------------------------
-- Main Loop
---------------------------------------------
local function loop()
    local play_state = reaper.GetPlayState()
    local is_playing = (play_state & 1) == 1
    local is_recording = (play_state & 4) == 4

    local color_bg = is_recording and 0xFF0000FF or is_playing and 0x00AA00FF or 0x000000FF
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_WindowBg(), color_bg)

    reaper.ImGui_SetNextWindowSize(ctx, 400, 200, reaper.ImGui_Cond_FirstUseEver())
    reaper.ImGui_SetNextWindowPos(ctx, 300, 200, reaper.ImGui_Cond_FirstUseEver())

    --local visible, open = reaper.ImGui_Begin(ctx, 'Dynamic TC Display', true)
    local flags = reaper.ImGui_WindowFlags_AlwaysAutoResize() + reaper.ImGui_WindowFlags_NoTitleBar() + reaper.ImGui_WindowFlags_NoCollapse()
    local visible, open = reaper.ImGui_Begin(ctx, '##tc_display', true, flags)
    

    if visible then
        if is_recording then
            if not recording_start_time then
                recording_start_time = reaper.GetPlayPosition()
            end
            local now = reaper.GetPlayPosition()
            local duration = now - recording_start_time
            local pos_str = format_timecode(now)
            local duration_str = format_timecode(duration)

            reaper.ImGui_PushFont(ctx, font_big, BIG_FONT_SIZE)
            reaper.ImGui_TextColored(ctx, 0xFFFFFFFF, "REC: " .. duration_str)
            reaper.ImGui_PopFont(ctx)

            reaper.ImGui_PushFont(ctx, font_small, SMALL_FONT_SIZE)
            reaper.ImGui_TextColored(ctx, 0xFFFFFFFF, "Position: " .. pos_str)
            reaper.ImGui_PopFont(ctx)

        elseif is_playing then
            recording_start_time = nil
            local pos = reaper.GetPlayPosition()
            reaper.ImGui_PushFont(ctx, font_big,41 )
            reaper.ImGui_TextColored(ctx, 0xFFFFFFFF, "Play: " .. format_timecode(pos))
            reaper.ImGui_PopFont(ctx)

        else
            recording_start_time = nil
            local item_count = reaper.CountSelectedMediaItems(0)
            local time_sel_start, time_sel_end = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)

            if item_count > 0 then
                local item = reaper.GetSelectedMediaItem(0, item_count - 1)
                local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")

                local name = "Sans nom"
                local ok, item_name = reaper.GetSetMediaItemInfo_String(item, "P_NAME", "", false)
                if ok and item_name ~= "" then
                    name = item_name
                else
                    local take = reaper.GetActiveTake(item)
                    if take then
                        local take_name = reaper.GetTakeName(take)
                        name = take_name and remove_extension(take_name) or name
                    end
                end

                local tc = format_timecode(pos)
                reaper.ImGui_PushFont(ctx, font_main, FONT_SIZE)
                reaper.ImGui_TextColored(ctx, 0x00FF00FF, "        Item Selected              " )
                reaper.ImGui_TextColored(ctx, 0xFFFFFFFF, name .. " | " .. tc)
                reaper.ImGui_PopFont(ctx)

            elseif time_sel_end > time_sel_start then
                local duration = time_sel_end - time_sel_start
                local dur_str = format_timecode(duration)

                reaper.ImGui_PushFont(ctx, font_small, SMALL_FONT_SIZE)
                reaper.ImGui_TextColored(ctx, 0x00FF00FF, "  S t a r t         " .. format_timecode(time_sel_start).."         S t a r t    ")
                reaper.ImGui_TextColored(ctx, 0xFF0F0FF, "   E n d            " .. format_timecode(time_sel_end).."           E n d    ")
                reaper.ImGui_TextColored(ctx, 0xFFFF00FF, "L e n g t h      " .. dur_str.."       L e n g t h       ")
                reaper.ImGui_PopFont(ctx)

            else
                -- Default: show cursor position + Go To Marker input
                local pos = reaper.GetCursorPosition()
                reaper.ImGui_PushFont(ctx, font_mid, MID_FONT_SIZE)
                reaper.ImGui_TextColored(ctx, 0xFFFFFFFF, " Position " .. format_timecode(pos))
                reaper.ImGui_PopFont(ctx)

                -----------------------------------------
                -- NEW: Go To Marker (auto on Return)
                -----------------------------------------
                reaper.ImGui_Separator(ctx)
                reaper.ImGui_SameLine(ctx,nil,40)
                reaper.ImGui_PushFont(ctx, font_main, 15)  -- 28 = nouvelle taille souhaitée
                reaper.ImGui_Text(ctx, "Go To Marker (Press Enter):")
                reaper.ImGui_PopFont(ctx)
                reaper.ImGui_SetNextItemWidth(ctx, 40)
                reaper.ImGui_SameLine(ctx)

                local changed_marker, new_val = reaper.ImGui_InputText(ctx, "##MarkerInput", marker_input, reaper.ImGui_InputTextFlags_EnterReturnsTrue())
                if changed_marker then marker_input = new_val end

                if reaper.ImGui_IsItemDeactivatedAfterEdit(ctx) then
                    go_to_marker(marker_input)
                end
            end
        end

        reaper.ImGui_End(ctx)
    end

    reaper.ImGui_PopStyleColor(ctx)

    if open then
        reaper.defer(loop)
    end
end

---------------------------------------------
-- Start
---------------------------------------------
reaper.defer(loop)
