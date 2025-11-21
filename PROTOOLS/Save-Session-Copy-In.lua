--[[
@description SaveSessionCopyIn
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-11-21)
  - Initial release
  - Creates a full "Session Copy In" workflow similar to Pro Tools
  - Copies project and referenced media with a live progress bar
  - Updates all media paths inside the duplicated .RPP
  - Includes auto-close and window close (croix) handling
@provides
  [main] PROTOOLS/Save-Session-Copy-In.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags project, copy, media, session, protTools, utility, management
@about
  # Pro Tools–Style "Save Session Copy In" for REAPER
  Recreates the behavior of Pro Tools' "Save Session Copy In" inside REAPER.
  This script scans all media referenced by the current project, allows the
  user to choose which files to include, and performs a clean project duplication
  with automatic media copying and path remapping inside the new .RPP file.

  A live progress bar provides feedback throughout the copying process, and the
  script closes automatically once the operation completes.
--]]

local reaper = reaper
local ctx = reaper.ImGui_CreateContext("Save Session Copy In", 0)

-- Project info
local retval, full_proj_path = reaper.EnumProjects(-1, "")
local project_path = full_proj_path:match("^(.*)/") or ""
local project_name = full_proj_path:match(".*/(.*)$") or ""

local media_files = {}
local dest_folder = ""
local audio_folder = "" -- new

-- Progress
local copy_queue = {}
local copying = false
local copied_files = 0
local total_files = 0
local media_map = {}
local running = true

-- Helpers
local function file_copy_safe(src, dest)
    local f = io.open(src, "rb")
    if not f then return false end
    f:close()

    -- ensure destination folder exists
    os.execute(string.format('mkdir "%s"', dest:match("^(.*)/")))

    local fsrc = io.open(src, "rb")
    if not fsrc then return false end
    local fdest = io.open(dest, "wb")
    if not fdest then return false end
    fdest:write(fsrc:read("*all"))
    fsrc:close()
    fdest:close()
    return true
end

local function escape_for_pattern(str)
    return str:gsub("([%.%+%-%^%$%(%)%%])", "%%%1")
end

----------------------------------------------------------------------
-- Scan Project Media (always include all)
----------------------------------------------------------------------
local function ScanProjectMedia()
    media_files = {}
    local num_items = reaper.CountMediaItems(0)
    local file_set = {}

    for i = 0, num_items - 1 do
        local item = reaper.GetMediaItem(0, i)
        local take = reaper.GetActiveTake(item)
        if take then
            local source = reaper.GetMediaItemTake_Source(take)
            local path = reaper.GetMediaSourceFileName(source, "")
            file_set[path] = true
        end
    end

    for path, _ in pairs(file_set) do
        table.insert(media_files, path)
    end
end

ScanProjectMedia()

----------------------------------------------------------------------
-- Initialize copy queue
----------------------------------------------------------------------
local function InitCopyQueue()
    copy_queue = {}
    media_map = {}

    audio_folder = dest_folder .. "/AudioFiles"

    -- create audio folder
    os.execute(string.format('mkdir "%s"', audio_folder))

    -- 1: copy project file
    table.insert(copy_queue, full_proj_path)

    -- 2: copy all media files
    for _, file in ipairs(media_files) do
        table.insert(copy_queue, file)
    end

    total_files = #copy_queue
    copied_files = 0
    copying = true
end

----------------------------------------------------------------------
-- Copy one file per loop
----------------------------------------------------------------------
local function CopyStep()
    if #copy_queue == 0 then
        -- update RPP: remap paths
        local new_proj_path = dest_folder .. "/" .. project_name
        local f = io.open(new_proj_path, "rb")

        if f then
            local content = f:read("*all")
            f:close()

            for orig, newp in pairs(media_map) do
                content = content:gsub(escape_for_pattern(orig), newp)
            end

            local f2 = io.open(new_proj_path, "wb")
            if f2 then
                f2:write(content)
                f2:close()
            end
        end

        copying = false
        reaper.ShowMessageBox("Project copy completed!\nAll media placed in /AudioFiles.", "Done", 0)
        running = false
        return
    end

    local current_file = table.remove(copy_queue, 1)
    local fname = current_file:match(".*/(.*)$") or current_file
    local dest_file

    -- RPP stays at root / media go to /AudioFiles
    if current_file == full_proj_path then
        dest_file = dest_folder .. "/" .. project_name
    else
        dest_file = audio_folder .. "/" .. fname
    end

    if file_copy_safe(current_file, dest_file) and current_file ~= full_proj_path then
        media_map[current_file] = dest_file
    end

    copied_files = copied_files + 1
end

----------------------------------------------------------------------
-- GUI Loop
----------------------------------------------------------------------
function Loop()
    if not running then return end

    reaper.ImGui_SetNextWindowSize(ctx, 600, 280, reaper.ImGui_Cond_FirstUseEver())
    local visible, open = reaper.ImGui_Begin(ctx, "Save Session Copy In", true)

    if not open then running = false end

    if visible then
        reaper.ImGui_Text(ctx, "Current project: " .. project_name)

        reaper.ImGui_Separator(ctx)
        reaper.ImGui_Text(ctx, "Destination folder:")

        if dest_folder ~= "" then
            reaper.ImGui_Text(ctx, dest_folder)
        else
            reaper.ImGui_Text(ctx, "(not set)")
        end

        if reaper.ImGui_Button(ctx, "Choose Destination Folder") then
            local ok, path = reaper.JS_Dialog_BrowseForFolder("Select Destination Folder", project_path)
            if ok then dest_folder = path end
        end

        reaper.ImGui_Separator(ctx)
        reaper.ImGui_Text(ctx, "AUDIOS will be placed in : /AudioFiles")

        reaper.ImGui_Separator(ctx)

        if copying then
            local progress = copied_files / total_files
            reaper.ImGui_ProgressBar(ctx, progress, -1, 0,
                string.format("%.0f%%", progress * 100))
            CopyStep()
        end

        if reaper.ImGui_Button(ctx, "Copy Project") and not copying then
            if dest_folder == "" then
                reaper.ShowMessageBox("Please select a destination folder first.", "Error", 0)
            else
                reaper.Main_SaveProject(0, false)
                InitCopyQueue()
            end
        end
    end

    reaper.ImGui_End(ctx)
    if running then reaper.defer(Loop) end
end

Loop()

