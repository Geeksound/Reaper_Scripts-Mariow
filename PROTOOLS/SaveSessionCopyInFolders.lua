--[[
@description Media Matrix Router – Advanced Session Copy In (4-Folder Routing)
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-11-21))
  - Initial release
@provides
  [main] PROTOOLS/SaveSessionCopyInFolders.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags media, routing, project, copy, session, matrix, protTools, utility, management
@about
  # Media Matrix Router – Pro Tools-Style “Save Session Copy In”, Evolved

  This script is an advanced version of the original **Save Session Copy In**
  workflow, expanding it with a complete **media routing matrix** inspired by
  high-end post-production tools.

  ## Features
  - Scans all media referenced in the current project  
  - Displays an interactive 4-folder matrix to route each media file  
  - Allows renaming of destination folders  
  - Safely copies the project and all referenced media  
  - Performs live, incremental file-copying with progress bar  
  - Builds a clean duplicate session with accurate media remapping  
  - Automatically updates all media paths inside the new .RPP  
  - Includes window close (X) handling and auto-close at end  

  A powerful tool for organizing media into structured subdirectories while
  creating clean, portable and production-ready session copies — similar to
  high-end DAWs like Pro Tools, but extended with custom folder routing.
--]]


local reaper = reaper
local ctx = reaper.ImGui_CreateContext("Media Matrix Router", 0)

local retval, full_proj_path = reaper.EnumProjects(-1, "")
local project_path = full_proj_path:match("^(.*)/") or ""
local project_name = full_proj_path:match(".*/(.*)$") or ""

-----------------------------------------------------
--  Data
-----------------------------------------------------
local media_files = {}
local folder_names = {"Folder A", "Folder B", "Folder C", "Folder D"}
local routing = {}
local dest_root = ""

local copying = false
local copy_queue = {}
local media_map = {}
local copied_files = 0
local total_files = 0
local running = true

-----------------------------------------------------
-- Helpers
-----------------------------------------------------
local function escape_for_pattern(str)
    return str:gsub("([%.%+%-%^%$%(%)%%])", "%%%1")
end

local function file_copy_safe(src, dest)
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

-----------------------------------------------------
-- Scan médias
-----------------------------------------------------
local function ScanProjectMedia()
    media_files = {}
    routing = {}

    local set = {}
    local item_count = reaper.CountMediaItems(0)

    for i=0,item_count-1 do
        local item = reaper.GetMediaItem(0,i)
        local take = reaper.GetActiveTake(item)
        if take then
            local src = reaper.GetMediaItemTake_Source(take)
            local p = reaper.GetMediaSourceFileName(src, "")
            set[p] = true
        end
    end

    for path,_ in pairs(set) do
        table.insert(media_files, path)
        routing[path] = 1    -- par défaut : Folder A
    end
end

ScanProjectMedia()

-----------------------------------------------------
-- Init copie
-----------------------------------------------------
local function InitCopyProcess()
    copy_queue = {}
    media_map = {}

    for i=1,4 do
        os.execute(string.format('mkdir "%s/%s"', dest_root, folder_names[i]))
    end

    table.insert(copy_queue, full_proj_path)

    for _,file in ipairs(media_files) do
        table.insert(copy_queue, file)
    end

    copied_files = 0
    total_files = #copy_queue
    copying = true
end

-----------------------------------------------------
-- Copie step-by-step
-----------------------------------------------------
local function CopyStep()
    if #copy_queue == 0 then
        local new_rpp = dest_root .. "/" .. project_name
        local f = io.open(new_rpp, "rb")
        if f then
            local content = f:read("*all")
            f:close()

            for orig,newp in pairs(media_map) do
                content = content:gsub(escape_for_pattern(orig), newp)
            end

            local f2 = io.open(new_rpp, "wb")
            if f2 then f2:write(content) f2:close() end
        end

        copying = false
        reaper.ShowMessageBox("Copy Completed!", "Done", 0)
        running = false
        return
    end

    local file = table.remove(copy_queue, 1)
    local fname = file:match(".*/(.*)$") or file

    local dest
    if file == full_proj_path then
        dest = dest_root .. "/" .. project_name
    else
        local folder = folder_names[routing[file]]
        dest = string.format("%s/%s/%s", dest_root, folder, fname)
        media_map[file] = dest
    end

    file_copy_safe(file, dest)
    copied_files = copied_files + 1
end

-----------------------------------------------------
-- UI LOOP
-----------------------------------------------------
function Loop()
    if not running then return end

    reaper.ImGui_SetNextWindowSize(ctx, 850, 520, reaper.ImGui_Cond_FirstUseEver())
    local visible,open = reaper.ImGui_Begin(ctx, "Media Matrix Router", true)

    if not open then running=false end
    if visible then

        -------------------------------------------------
        -- Dossier destination
        -------------------------------------------------
        reaper.ImGui_Text(ctx, "Destination folder:")
        if dest_root ~= "" then
            reaper.ImGui_Text(ctx, dest_root)
        else
            reaper.ImGui_Text(ctx, "(none)")
        end
        
        if reaper.ImGui_Button(ctx, "Choose Folder") then
            local ok,path = reaper.JS_Dialog_BrowseForFolder("Choose", project_path)
            if ok then dest_root = path end
        end

        reaper.ImGui_Separator(ctx)

        -------------------------------------------------
        -- Noms des 4 dossiers
        -------------------------------------------------
        reaper.ImGui_Text(ctx, "Folder names:")
        for i=1,4 do
            local changed,new = reaper.ImGui_InputText(ctx, "##folder"..i, folder_names[i])
            if changed then folder_names[i] = new end
            reaper.ImGui_SameLine(ctx)
            reaper.ImGui_Text(ctx, "← Folder "..i)
        end

        reaper.ImGui_Separator(ctx)

        -------------------------------------------------
        -- MATRICE
        -------------------------------------------------
        if reaper.ImGui_BeginTable(ctx, "matrix", 5) then
            reaper.ImGui_TableSetupColumn(ctx, "Media")
            for i=1,4 do
                reaper.ImGui_TableSetupColumn(ctx, folder_names[i])
            end
            reaper.ImGui_TableHeadersRow(ctx)

            for _,file in ipairs(media_files) do
                local name = file:match(".*/(.*)$") or file

                reaper.ImGui_TableNextRow(ctx)
                reaper.ImGui_TableSetColumnIndex(ctx, 0)
                reaper.ImGui_Text(ctx, name)

                for col=1,4 do
                    reaper.ImGui_TableSetColumnIndex(ctx, col)

                    local clicked = reaper.ImGui_RadioButton(
                        ctx, 
                        "##"..file..col, 
                        (routing[file] == col)
                    )
                    if clicked then
                        routing[file] = col
                    end
                end
            end

            reaper.ImGui_EndTable(ctx)
        end

        reaper.ImGui_Separator(ctx)

        -------------------------------------------------
        -- COPY / PROGRESS
        -------------------------------------------------
        if copying then
            local p = copied_files / total_files
            reaper.ImGui_ProgressBar(ctx, p, -1, 0,
                string.format("%.0f%%", p*100))
            CopyStep()
        elseif reaper.ImGui_Button(ctx, "COPY SESSION") then
            if dest_root == "" then
                reaper.ShowMessageBox("Choose a destination folder first.", "Error", 0)
            else
                reaper.Main_SaveProject(0, false)
                InitCopyProcess()
            end
        end
    end

    reaper.ImGui_End(ctx)
    if running then reaper.defer(Loop) end
end

Loop()

