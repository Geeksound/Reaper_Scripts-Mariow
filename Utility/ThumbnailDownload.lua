--[[ 
  @description Downloads Mariow’s thumbnail into the user’s Scripts directory to ensure it displays properly in his scripts
  @version 1.0
  @author Mariow
  @changelog
    v1.0 (2025-10-29)
    - Initial release
  @provides
    [main] Utility/ThumbnailDownload.lua
  @link https://github.com/Geeksound/Reaper_Scripts-Mariow
  @repository https://github.com/Geeksound/Reaper_Scripts-Mariow
  @tags thumbnail, image, scripts, installer
  @about
    # ThumbnailDownload
    This script downloads Mariow’s thumbnail image from GitHub and places it into the user’s REAPER Scripts directory, 
    ensuring it is available for other scripts.
--]]


-- URL on GitHub
local URL = "https://raw.githubusercontent.com/Geeksound/Reaper_Scripts-Mariow/main/PICTURES/Vignette.png"

-- Nom du fichier local
local FILE_NAME = "Vignette.png"

-- Fonction to download 'Vignette.png'from GitHub via curl
local function DownloadFile(url, dest_path)
  local tmp = reaper.GetResourcePath() .. "/temp_vignette_download.png"
  local command = string.format('curl -L -o "%s" "%s"', tmp, url)
  os.execute(command)

  local file = io.open(tmp, "rb")
  if not file then return false, "Download failed (curl not available or URL is invalid)" end
  local data = file:read("*all")
  file:close()

  local out = io.open(dest_path, "wb")
  if not out then return false, "Cannot write file in : " .. dest_path end
  out:write(data)
  out:close()

  os.remove(tmp)
  return true
end

-- Fonction principale
local function Main()
  local scripts_dir = reaper.GetResourcePath() .. "/Scripts"
  local dest = scripts_dir .. "/" .. FILE_NAME

  -- Vérifie si le fichier existe déjà
  local f = io.open(dest, "rb")
  if f then
    f:close()
    local ret = reaper.ShowMessageBox(
      "The thumbnail already exists in :\n" .. dest .. "\n\nDo you want to replace it ?",
      "Mariow thumbnail already present",
      4
    )
    if ret ~= 6 then return end -- 6 = "Yes"
  end

  local ok, err = DownloadFile(URL, dest)
  if ok then
    reaper.ShowMessageBox("✅ Thumbnail successfully installed in :\n" .. dest, "Succes", 0)
  else
    reaper.ShowMessageBox("❌ Error : " .. tostring(err), "Thumbnail download failed", 0)
  end
end

-- Exécution
reaper.Undo_BeginBlock()
Main()
reaper.Undo_EndBlock("Mariow Thumbnail Download", -1)

