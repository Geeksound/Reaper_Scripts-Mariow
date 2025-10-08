--[[
@description Interactive-TC-Display
@version 1.2
@author Mariow
@license MIT
@changelog
  V1.2 (2025-09-08)
  - ReaImguiV0.10.02 Font Compatibility
  v1.0 (2025-06-08)
  - Initial release
@provides
  [main] View/Interactive-TC-Display.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags timecode display reaper contextual items status
@about
  # Interactive-TC-Display

  Contextual display of TimeCode / Items / Status for Reaper 7.0.
--]]


local ctx = reaper.ImGui_CreateContext('Interactive-TC-Display')
local FONT_SIZE = 24
local BIG_FONT_SIZE = 46
local SMALL_FONT_SIZE = 16
local MID_FONT_SIZE = 36

local font_main = reaper.ImGui_CreateFont('Comic Sans MS')
local font_big = reaper.ImGui_CreateFont('Arial')
local font_small = reaper.ImGui_CreateFont('Comic')
local font_mid = reaper.ImGui_CreateFont('Arial')
reaper.ImGui_Attach(ctx, font_main)
reaper.ImGui_Attach(ctx, font_big)
reaper.ImGui_Attach(ctx, font_small)
reaper.ImGui_Attach(ctx, font_mid)

local recording_start_time = nil

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

local function loop()
local play_state = reaper.GetPlayState()
local is_playing = (play_state & 1) == 1
local is_recording = (play_state & 4) == 4

local color_bg = is_recording and 0xFF0000FF or is_playing and 0x00AA00FF or 0x000000FF
reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_WindowBg(), color_bg)

reaper.ImGui_SetNextWindowSize(ctx, 400, 200, reaper.ImGui_Cond_FirstUseEver())
reaper.ImGui_SetNextWindowPos(ctx, 300, 200, reaper.ImGui_Cond_FirstUseEver())

local visible, open = reaper.ImGui_Begin(ctx, 'Dynamic TC Display', true)
--reaper.ImGui_WindowFlags_NoTitleBar() |
--reaper.ImGui_WindowFlags_NoResize() |
--reaper.ImGui_WindowFlags_NoMove() |
--reaper.ImGui_WindowFlags_NoCollapse()
--)

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
reaper.ImGui_PushFont(ctx, font_big, BIG_FONT_SIZE)
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

reaper.ImGui_TextColored(ctx, 0x00FF00FF, "                  Item Selected        " )
reaper.ImGui_TextColored(ctx, 0xFFFFFFFF, name .. " | " .. tc)
reaper.ImGui_PopFont(ctx)

elseif time_sel_end > time_sel_start then
local duration = time_sel_end - time_sel_start
local dur_str = format_timecode(duration)

reaper.ImGui_PushFont(ctx, font_small, FONT_SMALL_SIZE)
reaper.ImGui_TextColored(ctx, 0x00FF00FF, "Start            " .. format_timecode(time_sel_start))
reaper.ImGui_TextColored(ctx, 0xFF0F0FF, "End             " .. format_timecode(time_sel_end))
reaper.ImGui_TextColored(ctx, 0xFFFF00FF, "L e n g t h    " .. dur_str)
reaper.ImGui_PopFont(ctx)

else
local pos = reaper.GetCursorPosition()
reaper.ImGui_PushFont(ctx, font_mid, MID_FONT_SIZE)
reaper.ImGui_TextColored(ctx, 0xFFFFFFFF, " Position " .. format_timecode(pos))
reaper.ImGui_PopFont(ctx)
end
end

reaper.ImGui_End(ctx)
end

reaper.ImGui_PopStyleColor(ctx)

if open then
reaper.defer(loop)
end
end

reaper.defer(loop)