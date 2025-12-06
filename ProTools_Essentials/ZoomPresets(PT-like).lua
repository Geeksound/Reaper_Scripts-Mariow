--[[
@description Zoom Presets H+V (4 slots) - ProTools-like
@version 1.0 (2025-12-06)
@author Mariow
@changelog
  v1.0 (2025-12-06)
  - Dockable ImGui panel
  - 4 horizontal + vertical zoom presets
  - ALT+Click to save current H+V zoom
  - Click to recall zoom (ProTools-like)
  - Compatible with all ReaImGui versions
@provides
  [main] ProTools_Essentials/ZoomPresets(PT-like).lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags zoom, presets, arrange, vertical, horizontal, dockable, (protools-like)
@about
  # Zoom Presets H+V (4 slots) - ProTools-like
  This script provides a dockable REAPER panel that mimics ProTools’ zoom presets.
  - ALT + click a button to save current horizontal + vertical zoom.
  - Click button to restore the saved zoom.
  - 4 slots available.
--]]


local reaper = reaper

------------------------------------------------------------
-- CREATE DOCKABLE IMGUI CONTEXT (compatible method)
------------------------------------------------------------

-- Docking enabled directly here (no GetIO needed)
local ctx = reaper.ImGui_CreateContext(
    'Zoom Presets',
    reaper.ImGui_ConfigFlags_DockingEnable()
)

local font = reaper.ImGui_CreateFont('sans-serif', 16)
reaper.ImGui_Attach(ctx, font)

------------------------------------------------------------
-- PRESETS CONFIG
------------------------------------------------------------

local presets = {
    {label = "1", id = 1, align = true},
    {label = "2", id = 2, align = false},
    {label = "3", id = 3, align = true},
    {label = "4", id = 4, align = false},
}

------------------------------------------------------------
-- SAVE / LOAD HORIZONTAL ZOOM
------------------------------------------------------------

local function save_hzoom(p)
    local s = reaper.GetExtState("ToolbarZoom_Mariow_H", "sizes")
    local list = {0,0,0,0}
    local i = 0

    if s ~= "" then
        for n in s:gmatch("%S+") do
            i = i + 1
            list[i] = tonumber(n)
        end
    end

    local a, b = reaper.GetSet_ArrangeView2(0, false, 0, 0)
    list[p] = math.floor((b - a) * 100) / 100

    reaper.SetExtState("ToolbarZoom_Mariow_H", "sizes", table.concat(list, " "), true)
end

local function load_hzoom(p)
    local s = reaper.GetExtState("ToolbarZoom_Mariow_H", "sizes")
    if s == "" then return end

    local list = {}
    for n in s:gmatch("%S+") do list[#list+1] = tonumber(n) end
    local zoom = list[p]
    if not zoom then return end

    local cur_start, cur_end = reaper.GetSet_ArrangeView2(0, false, 0, 0)
    local cur_len = cur_end - cur_start
    local center_pos = reaper.GetCursorPosition()

    if center_pos <= cur_start or center_pos >= cur_end then
        center_pos = cur_start + cur_len / 2
    end

    local sz_L = ((center_pos - cur_start) / cur_len) * zoom
    local sz_R = ((cur_end - center_pos) / cur_len) * zoom
    local adj = (center_pos - sz_L < 0) and (sz_L - center_pos) or 0

    reaper.GetSet_ArrangeView2(0, true, 0, 0,
        center_pos - sz_L + adj,
        center_pos + sz_R + adj
    )
end

------------------------------------------------------------
-- SAVE / LOAD VERTICAL ZOOM
------------------------------------------------------------

local function save_vzoom(p)
    local s = reaper.GetExtState("ToolbarZoom_Mariow_V", "sizes")
    local list = {0,0,0,0}
    local i = 0

    if s ~= "" then
        for n in s:gmatch("%S+") do
            i = i + 1
            list[i] = tonumber(n)
        end
    end

    list[p] = reaper.SNM_GetIntConfigVar("vzoom2", -1)
    reaper.SetExtState("ToolbarZoom_Mariow_V", "sizes", table.concat(list, " "), true)
end

local function load_vzoom(p)
    local s = reaper.GetExtState("ToolbarZoom_Mariow_V", "sizes")
    if s == "" then return end

    local list = {}
    for n in s:gmatch("%S+") do list[#list+1] = tonumber(n) end
    local wanted = list[p]
    if not wanted then return end

    local arrange = reaper.JS_Window_FindChildByID(reaper.GetMainHwnd(), 1000)
    if not arrange then return end

    local ok, pos, page, _, max =
        reaper.JS_Window_GetScrollInfo(arrange, "v")
    if not ok then return end

    reaper.SNM_SetIntConfigVar("vzoom2", wanted)
    reaper.TrackList_AdjustWindows(true)

    local ok2, _, newPage, _, newMax =
        reaper.JS_Window_GetScrollInfo(arrange, "v")
    if ok2 then
        local new_pos = math.floor((pos + page/2) * (newMax / max) - newPage/2 + 0.5)
        reaper.JS_Window_SetScrollPos(arrange, "v", new_pos)
    end
end

------------------------------------------------------------
-- GUI LOOP
------------------------------------------------------------

local function loop()
    local flags =
          reaper.ImGui_WindowFlags_AlwaysAutoResize()
        | reaper.ImGui_WindowFlags_NoCollapse()

    local visible, open =
        reaper.ImGui_Begin(ctx, 'Zoom Presets', true, flags)

    if visible then
        reaper.ImGui_PushFont(ctx, font,14)

        local mods = reaper.ImGui_GetKeyMods(ctx)
        local alt = (mods & reaper.ImGui_Mod_Alt()) ~= 0

        for i, p in ipairs(presets) do
            
            local label = alt and ("S" .. p.label) or p.label

            if reaper.ImGui_Button(ctx, label, 20, 22) then
                if alt then
                    save_hzoom(p.id)
                    save_vzoom(p.id)
                else
                    load_hzoom(p.id)
                    load_vzoom(p.id)
                end
            end

            if p.align then
                reaper.ImGui_SameLine(ctx, 0, 10)
            else
                if i == 2 then
                    reaper.ImGui_Separator(ctx)
                end
            end
        end

        reaper.ImGui_PopFont(ctx)
    end

    reaper.ImGui_End(ctx)

    if open then
        reaper.defer(loop)
    else
        reaper.ImGui_DestroyContext(ctx)
    end
end

reaper.defer(loop)

