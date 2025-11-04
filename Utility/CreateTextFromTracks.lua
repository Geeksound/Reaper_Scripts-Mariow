--[[
@description CreateTextFromTracks
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-11-04)
  - Initial release
@provides
  [main] Utility/CreateTextFromTracks.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags template
@about
  # CreateTextFromTracks
  Contextual Create a file.txt from Name/Parent/children/Spacer and colors of your session tracks.
  It may be modified or not  and  then used by CreaTracksFromText.lua to retrieve your session
  This script was developed with the help of GitHub Copilot.
--]]

function Msg(str)
    reaper.ShowConsoleMsg(tostring(str) .. "\n")
end

-- Convert REAPER native color to RGB
function ColorFromNative(color)
    local r = color & 0xFF
    local g = (color >> 8) & 0xFF
    local b = (color >> 16) & 0xFF
    return r, g, b
end

-- Convert RGB to approximate color name
local function RGBtoName(r, g, b)
    local colors = {
        red={255,0,0}, green={0,200,0}, blue={0,120,255},
        yellow={255,255,0}, purple={180,0,255}, orange={255,140,0},
        pink={255,100,180}, gray={120,120,120}, white={255,255,255}, black={0,0,0}
    }
    for name, rgb in pairs(colors) do
        if r==rgb[1] and g==rgb[2] and b==rgb[3] then
            return name
        end
    end
    return nil
end

-- Ask user for a file name (cross-version compatible)
local retval, file_name = reaper.GetUserInputs("Save text file", 1, "File name (with .txt)", "export.txt")
if not retval then return end

-- Determine full path in the REAPER project folder
local project_path = reaper.GetProjectPath("")
local file_path = project_path .. "/" .. file_name

-- Retrieve all tracks
local trackCount = reaper.CountTracks(0)
local track_data = {}

for i = 0, trackCount-1 do
    local track = reaper.GetTrack(0, i)
    local _, name = reaper.GetTrackName(track)
    local color = reaper.GetMediaTrackInfo_Value(track, "I_CUSTOMCOLOR")
    local r,g,b = 0,0,0
    if color ~= 0 then r,g,b = ColorFromNative(color) end
    local folder_depth = reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH")
    local isSpacer = reaper.GetMediaTrackInfo_Value(track, "I_SPACER")
    table.insert(track_data, {
        name = name,
        r = r,
        g = g,
        b = b,
        folder_depth = folder_depth,
        isSpacer = isSpacer
    })
end

-- Calculate hierarchical depth
local depth_stack = {}
for i, t in ipairs(track_data) do
    if t.folder_depth == 1 then
        table.insert(depth_stack, 1)
    elseif t.folder_depth < 0 then
        for j=1, -t.folder_depth do table.remove(depth_stack) end
    end
    t.depth = #depth_stack
end

-- Create and write to the file
local file = io.open(file_path, "w")
if not file then
    reaper.ShowMessageBox("Cannot open file for writing.", "Error", 0)
    return
end

for i, t in ipairs(track_data) do
    local indent = string.rep("    ", t.depth)
    if t.isSpacer ~= 0 or t.name=="" then
        file:write(indent .. "\n") -- spacer = empty line
    else
        local color_name = RGBtoName(t.r,t.g,t.b)
        if color_name then
            file:write(indent .. t.name .. " (" .. color_name .. ")\n")
        else
            file:write(indent .. t.name .. "\n")
        end
    end
end

file:close()
reaper.ShowMessageBox("Export complete: "..file_path, "Info", 0)

