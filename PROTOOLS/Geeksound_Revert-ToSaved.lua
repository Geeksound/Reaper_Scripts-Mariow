--[[
@description RevertToSaved
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-11-12)
  - Initial release
  - Simulates Pro Tools 'Revert to Saved' inside REAPER
  - Closes the current project and reopens the last saved version
@provides
  [main] PROTOOLS/RevertToSaved.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags project, revert, undo, workflow
@about
  # RevertToSaved
  Emulates the Pro Tools 'Revert to Saved' feature within REAPER.
  The script closes the current project (prompting to save if needed) 
  and reopens the last saved version of the project. 
  Useful for quickly undoing all unsaved changes.
--]]

-- 1. Récupérer le chemin du projet actif
local proj = 0 -- projet actuel
local retval, project_path = reaper.EnumProjects(proj, "")

if retval and project_path ~= "" then
    -- Simple message en anglais avant fermeture
    reaper.ShowMessageBox("Choose NO on the next DialogBox", "Warning", 0)

    -- 2. Fermer le projet actif (boîte de dialogue apparaitra)
    reaper.Main_OnCommand(40861, 0) -- File: Close current project

    -- 3. Ouvrir à nouveau ce projet
    reaper.Main_openProject(project_path)
else
    reaper.ShowMessageBox("No project saved or path not found.", "Error", 0)
end

