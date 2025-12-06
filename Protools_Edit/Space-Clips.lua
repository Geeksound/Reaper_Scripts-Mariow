--[[
@description Gap Between Items (Set or Remove Gaps) — Space-Clips (ProTools-like)
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-06-07)
  - Initial release
@provides
  [main] Protools_Edit/Space-Clips.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags editing, items, spacing, gaps, (protools-like)
@about
  # Space-Clips / Gap Between Items (ProTools-like)
  Creates or removes uniform gaps between selected items,
  mimicking Pro Tools' "Space Clips" feature.
  Gaps can be entered as timecode, milliseconds, or samples.
--]]


--========================================
-- ReaImGui Context & Fonts
--========================================
local ctx = reaper.ImGui_CreateContext('Gap Between Items')
local font_normal = reaper.ImGui_CreateFont('Arial')
local font_bold   = reaper.ImGui_CreateFont('Arial Bold')
reaper.ImGui_Attach(ctx, font_normal)
reaper.ImGui_Attach(ctx, font_bold)

--========================================
-- Core Values
--========================================
local project_sr = reaper.GetSetProjectInfo(0, 'PROJECT_SRATE', 0, false)
local fps = 25

local sample_pos = 0
local timecode_str = { "00:00:00:00" }
local milliseconds_val = { 0 }
local samples_val = { 0 }

--========================================
-- Timecode Utilities
--========================================
local function format_timecode(samples, sample_rate, fps)
    local total_seconds = samples / sample_rate
    local hours = math.floor(total_seconds / 3600)
    local minutes = math.floor((total_seconds % 3600) / 60)
    local seconds = math.floor(total_seconds % 60)
    local frames = math.floor((total_seconds - math.floor(total_seconds)) * fps + 0.5)
    return string.format("%02d:%02d:%02d:%02d", hours, minutes, seconds, frames)
end

local function parse_timecode_to_samples(tc)
    local h, m, s, f = tc:match("(%d+):(%d+):(%d+):(%d+)")
    if h and m and s and f then
        local total_seconds = tonumber(h)*3600 + tonumber(m)*60 + tonumber(s) + tonumber(f)/fps
        return math.floor(total_seconds * project_sr + 0.5)
    end
end

local function update_fields_from_samples()
    local sec = sample_pos / project_sr
    timecode_str[1] = format_timecode(sample_pos, project_sr, fps)
    milliseconds_val[1] = math.floor(sec * 1000 + 0.5)
    samples_val[1] = sample_pos
end

--========================================
-- GAP / REMOVE GAP Function
--========================================
local function SetOrRemoveGaps(gap_sec)
    local itemCount = reaper.CountSelectedMediaItems(0)
    if itemCount < 2 then
        reaper.ShowMessageBox("Select at least 2 Items", "Gap Between Items", 0)
        return
    end

    -- récupérer items triés
    local items = {}
    for i = 0, itemCount -1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        table.insert(items, {item=item, pos=pos, len=len})
    end
    table.sort(items, function(a,b) return a.pos < b.pos end)

    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)

    local cursor = items[1].pos

    if gap_sec == 0 then
        -- Remove gaps
        for i =1, #items do
            reaper.SetMediaItemInfo_Value(items[i].item, "D_POSITION", cursor)
            cursor = cursor + items[i].len
        end
        reaper.Undo_EndBlock("Remove Gaps", -1)
    else
        -- Set fixed gap
        for i =1, #items do
            reaper.SetMediaItemInfo_Value(items[i].item, "D_POSITION", cursor)
            cursor = cursor + items[i].len + gap_sec
        end
        reaper.Undo_EndBlock("Set Gap "..gap_sec.."s", -1)
    end

    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
end

--========================================
-- ImGui Loop
--========================================
local function loop()
    local visible, open = reaper.ImGui_Begin(ctx, "Gap Between Items", true, reaper.ImGui_WindowFlags_AlwaysAutoResize())
    if visible then
        -- Input fields
        local changed_tc, new_tc = reaper.ImGui_InputText(ctx, "Timecode (hh:mm:ss:ff)", timecode_str[1], 256)
        if changed_tc then local s = parse_timecode_to_samples(new_tc); if s then sample_pos = s; update_fields_from_samples() end end

        local changed_ms, new_ms = reaper.ImGui_InputInt(ctx, "Milliseconds", milliseconds_val[1])
        if changed_ms then sample_pos = math.floor((new_ms / 1000) * project_sr + 0.5); update_fields_from_samples() end

        local changed_smpl, new_smpl = reaper.ImGui_InputInt(ctx, "Samples", samples_val[1])
        if changed_smpl then sample_pos = new_smpl; update_fields_from_samples() end

        reaper.ImGui_Separator(ctx)

        -- Apply Button
        if reaper.ImGui_Button(ctx, "Apply Gap / Remove Gap", -1, 28) then
            local gap_sec = sample_pos / project_sr
            SetOrRemoveGaps(gap_sec)
        end

        reaper.ImGui_End(ctx)
    end

    if open then
        reaper.defer(loop)
    else
        if reaper.ImGui_DestroyContext then reaper.ImGui_DestroyContext(ctx) end
    end
end

reaper.defer(loop)

