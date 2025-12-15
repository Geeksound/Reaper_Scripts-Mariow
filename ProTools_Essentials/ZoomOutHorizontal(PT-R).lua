--[[
@description Zoom out horizontally (ProTools-like)
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-11-26)
  - Initial release: zooms out horizontally, Pro Tools R behavior
@provides
  [main] ProTools_Essentials/ZoomOutHorizontal(PT-R).lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags navigation, zoom, arrange, (protools-like)
@about
  # ZoomOutHorizontal (ProTools-like)
  Zooms out horizontally in the arrange view,
  emulating Pro Tools' R shortcut for horizontal zoom.
--]]

reaper.Main_OnCommand(reaper.NamedCommandLookup("_WOL_SETHZOOMC_EDITCUR"), 0)
reaper.Main_OnCommand(1011, 0)


