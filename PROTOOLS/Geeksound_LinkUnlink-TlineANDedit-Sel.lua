--[[
@description Toggle Link/Unlink TimelineEdit Selection
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-11-12)
  - Initial release
  - Toggle Timeline / Edit Selection link/unlink (Pro Tools style)
@provides
  [main] PROTOOLS/LinkUnlink-TimelineANDEdit-Sel.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags timeline, edit selection, link, unlink, Pro Tools
@about
  # Pro Tools Style Timeline & Edit Selection Link Toggle
  This script toggles the "Link/Unlink Timeline and Edit Selection" state,
  similar to Pro Tools.

  - Changes loop points / time selection link and edit cursor link (SWS)
  - Can be used together with LinkUnlink-TimelineANDEdit-SelOneKNOB.lua
    to quickly monitor the current state with a floating button.
  - Works with REAPER v6.80+ and SWS extension
  - Ideal for alternating selection behaviors during editing
--]]

local extSection = "ProToolsLink"
local extKey = "LinkState"

-- Vérifie l’état actuel
local state = reaper.GetExtState(extSection, extKey)
local newState

if state == "1" then
  -- 🔓 Passer en mode UNLINKED
  newState = "0"
  reaper.SetExtState(extSection, extKey, newState, true)
  
  -- Désactiver le lien loop points / time selection
  reaper.Main_OnCommand(40621, 0) -- Toggle loop points linked to time selection (désactive)
  
  -- Désactiver le lien time selection / edit cursor (SWS)
  reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_AWCLRTIMESELCLKTOG"), 0)

  --reaper.ShowMessageBox("Pro Tools Mode: UNLINKED\nTimeline & Edit Selection are independent.", "Pro Tools Link", 0)
  
else
  -- 🔗 Passer en mode LINKED
  newState = "1"
  reaper.SetExtState(extSection, extKey, newState, true)
  
  -- Activer le lien loop points / time selection
  reaper.Main_OnCommand(40621, 0) -- Toggle loop points linked to time selection (active)
  
  -- Activer le lien time selection / edit cursor (SWS)
  reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_AWCLRTIMESELCLKTOG"), 0)
  
  --reaper.ShowMessageBox("Pro Tools Mode: LINKED\nTimeline & Edit Selection are linked.", "Pro Tools Link", 0)
end

