--[[
@description Trim Left & Right using sliders with adjustable duration
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-11-06)
  - Added adjustable duration for trim range (1s → 10s)
  - Improved FPS handling (defaults to 25 if unset)
  - Smoother slider responsiveness and reset when duration changes
@provides
  [main] Editing_TRIM/Trim-LeftRight@range.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags items, editing, trimming, gui
@about
  # Trim Left & Right using sliders
  Interactive script to trim item edges in Reaper using two independent sliders.
  Each slider controls the left or right edge of the selected item(s) within a
  user-defined duration range (1s → 10s).  
  FPS is automatically retrieved from project settings for precise frame mapping.
--]]


local r = reaper
local ctx = r.ImGui_CreateContext('Trim Edges')
local FONT = r.ImGui_CreateFont('sans-serif', 12)
r.ImGui_Attach(ctx, FONT)

local trim_left_value = 0
local trim_right_value = 0
local duration_sec = 1 -- durée de trim max en secondes

-- Get FPS from project settings
local function get_fps()
    local fps = r.GetSetProjectInfo(0, "VIDEO_FPS", 0, false)
    if fps == 0 then fps = 25 end -- default if not set
    return math.floor(fps + 0.5)
end

local FPS = get_fps()

-- Execute command based on slider delta (map to frames)
local function execute_trim_slider(slider_value, last_value, cmd_left, cmd_right)
    local delta = slider_value - last_value
    local steps = math.floor(math.abs(delta))
    if steps > 0 then
        local cmd = (delta < 0) and cmd_left or cmd_right
        for i = 1, steps do
            r.Main_OnCommand(cmd, 0)
        end
    end
    return slider_value
end

local last_trim_left = 0
local last_trim_right = 0

function loop()
    r.ImGui_PushFont(ctx, FONT,12)
    local visible, open = r.ImGui_Begin(ctx, 'Trim Left & Right  (by Mariow)' , true)

    if visible then
        -- Setting Duration 
        r.ImGui_Text(ctx, "Max trim duration (seconds)")
        r.ImGui_SetNextItemWidth(ctx, 200)
        local changed_dur
        changed_dur, duration_sec = r.ImGui_SliderDouble(ctx, "##DurationSlider", duration_sec, 1, 10, "%.0f s")
        if changed_dur then
            trim_left_value = 0
            trim_right_value = 0
            last_trim_left = 0
            last_trim_right = 0
        end

        local max_frames = FPS * duration_sec

        r.ImGui_Separator(ctx)

        -- Slider Trim Left
        r.ImGui_Text(ctx, "Trim Left (" .. duration_sec .. "s range)")
        r.ImGui_SetNextItemWidth(ctx, 200)
        local changed
        changed, trim_left_value = r.ImGui_SliderDouble(ctx, "##LeftSlider", trim_left_value, -max_frames, max_frames, "%.0f")
        if changed then
            last_trim_left = execute_trim_slider(trim_left_value, last_trim_left, 40225, 40226)
        end

        r.ImGui_Separator(ctx)

        -- Slider Trim Right
        r.ImGui_Text(ctx, "Trim Right (" .. duration_sec .. "s range)")
        r.ImGui_SetNextItemWidth(ctx, 200)
        local changed2
        changed2, trim_right_value = r.ImGui_SliderDouble(ctx, "##RightSlider", trim_right_value, -max_frames, max_frames, "%.0f")
        if changed2 then
            last_trim_right = execute_trim_slider(trim_right_value, last_trim_right, 40227, 40228)
        end

        r.ImGui_End(ctx)
    end

    r.ImGui_PopFont(ctx)

    if open then
        r.defer(loop)
    end
end

loop()
