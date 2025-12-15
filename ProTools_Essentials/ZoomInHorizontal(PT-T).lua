--[[
@description Zoom in horizontally and scroll to cursor (ProTools-like)
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-11-26)
  - Initial release: zooms horizontally and scrolls arrange view to cursor, Pro Tools T behavior
@provides
  [main] ProTools_Essentials/ZoomInHorizontal(PT-T).lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags navigation, zoom, arrange, (protools-like)
@about
  # ZoomInHorizontal (ProTools-like)
  Zooms in horizontally on the arrange view and centers the cursor,
  emulating Pro Tools' T shortcut for horizontal zoom.
--]]
  
reaper.Main_OnCommand(reaper.NamedCommandLookup("_WOL_SETHZOOMC_EDITCUR"), 0)
reaper.Main_OnCommand(1012, 0)  -- Zoom in horizontally
--reaper.Main_OnCommand(40151, 0) -- Scroll horizontally to cursor


