--[[
@description Delete checked takes from 1 to 10
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-11-09)
  - Initial release
@provides
  [main] Editing/RemoveTakesByChoices.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags takes, media items, editing
@about
  # delete-selected-takes
  Displays a window to check and delete specific takes (from 1 to 10) 
  in the selected items in Reaper. Also removes empty takes after deletion.
  Developed with the help of GitHub Copilot.
--]]

if not reaper.ImGui_CreateContext then
    reaper.ShowMessageBox("ReaImGui is not installed. Go to ReaPack to install it.", "Error", 0)
    return
end

local ctx = reaper.ImGui_CreateContext("Delete Takes")
local visible = true
local to_delete = {}
for i = 1, 10 do to_delete[i] = false end

function loop()
    reaper.ImGui_SetNextWindowSize(ctx, 300, 300, reaper.ImGui_Cond_FirstUseEver())
    local open = reaper.ImGui_Begin(ctx, "Take Selection", true)
    if open then
        reaper.ImGui_Text(ctx, "Check the takes to delete (1 to 10)")
        for i = 1, 10 do
            local changed, val = reaper.ImGui_Checkbox(ctx, "Take " .. i, to_delete[i])
            if changed then to_delete[i] = val end
        end

        reaper.ImGui_Separator(ctx)

        if reaper.ImGui_Button(ctx, "Delete") then
            visible = false -- close next frame
            delete_takes()
        end

        reaper.ImGui_SameLine(ctx)
        if reaper.ImGui_Button(ctx, "Cancel") then
            visible = false
        end

        reaper.ImGui_End(ctx)
    else
        visible = false
    end

    if visible then
        reaper.defer(loop)
    else
        if reaper.ImGui_DestroyContext then
            reaper.ImGui_DestroyContext(ctx)
        end
    end
end

function delete_takes()
    local sel = reaper.CountSelectedMediaItems(0)
    if sel == 0 then
        reaper.ShowMessageBox("No items selected.", "Info", 0)
        return
    end

    -- Save selected items
    local selected_items = {}
    for i = 0, sel - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        if reaper.ValidatePtr(item, "MediaItem*") then
            selected_items[#selected_items + 1] = item
        end
    end

    reaper.Undo_BeginBlock()
    local total_deleted = 0

    for _, item in ipairs(selected_items) do
        local take_count = reaper.CountTakes(item)
        local takes_to_remove = {}

        for t = take_count - 1, 0, -1 do
            if to_delete[t + 1] then
                local take = reaper.GetMediaItemTake(item, t)
                if take then
                    table.insert(takes_to_remove, take)
                end
            end
        end

        for _, take in ipairs(takes_to_remove) do
            reaper.Main_OnCommand(40289, 0) -- deselect all
            reaper.SetMediaItemSelected(item, true)
            reaper.SetActiveTake(take)
            if reaper.GetActiveTake(item) == take then
                reaper.Main_OnCommand(40129, 0) -- delete active take
                total_deleted = total_deleted + 1
            end
        end
    end

    -- Reselect items so that command 41348 acts on them
    reaper.Main_OnCommand(40289, 0)
    for _, item in ipairs(selected_items) do
        if reaper.ValidatePtr(item, "MediaItem*") then
            reaper.SetMediaItemSelected(item, true)
        end
    end

    -- Remove empty takes
    reaper.Main_OnCommand(41348, 0)

    reaper.Undo_EndBlock("Delete checked takes + empty takes", -1)
    reaper.UpdateArrange()
end

-- Launch interface
reaper.defer(loop)

