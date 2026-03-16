--[[
@description Link-Timeselection and Edit(loop) (ProTools-like)
@version 1.0
@author Mariow
@changelog
  v1.0 (2026-03-15) 
  - Toggle loop points linked to time selection
  - Based on CommandID 40621 (Set Time Selection to Razor Edit area)
@provides
  [main] ProTools_Linking/Geeksound_LinkTimesel-edit(loop).lua 
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags edit, Linking (protools-like) 
@about
  # Link Edit & Timeline (ProTools-like)
  Emulates Pro Tools (Shift+/) shortcut
  Links Razor Edits to Time Selection and loop points automatically
--]]

-- CommandID 40621 = "Set time selection to Razor Edit area"
reaper.Main_OnCommand(40621, 0)


