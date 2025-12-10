--[[
@description Shrink Right Edge of selected items by Nudge Value (TimecodeUI)
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-12-09)
  - Initial release (shrinks right edge of selected items using TimecodeUI)
@provides
  [main] ProTools_Essentials/ShrinkRightEdge-TCui.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags editing, trim, nudge, items, transport, (protools-like)
@about
  # Shrink Right Edge by Nudge Value (ProTools-like)
  
  This script reduces the **length of selected items** by moving the **right edge**
  backward according to the nudge value defined in the companion **TimecodeUI** panel.
  
  ## 🟦 Timecode Input (Shared Setting)
  - Namespace: **"TimecodeUI"**
  - Key: **"tc"**
  - Format: `HH:MM:SS:FF` (frames based; currently 25 fps)
  
  Using this shared ExtState ensures consistent nudge behavior across all related scripts.
  
  ## 🟩 Usage
  - Only affects **selected items**.  
  - Right edge is reduced by the nudge value.  
  - Item length will not go below zero.  
  - Undo is fully supported via REAPER's undo system.
  
  ## 🔗 Part of the ProTools_Essentials Suite
  Works in conjunction with:
  
  - Grow Right Edge  
  - Grow Left Edge  
  - Trim Left Edge  
  - Trim Right Edge  
  - Nudge Forward / Nudge Backward  
  - PRE-POST-ROLL + Timecode UI (ImGui)  
  - Set_Rolls_And_Nudge_Settings  
  
  Together, these scripts create a unified, Pro Tools–inspired editing workflow in REAPER.
--]]


local function read_tc()
  local tc = reaper.GetExtState('TimecodeUI','tc')
  if not tc or tc == '' then return 0 end
  local h,m,s,f = tc:match('(%d+):(%d+):(%d+):(%d+)')
  if not h then return 0 end
  local fps = 25
  return h*3600 + m*60 + s + f/fps
end

local delta = read_tc()
if delta == 0 then return end

local sel_count = reaper.CountSelectedMediaItems(0)
if sel_count == 0 then return end

reaper.Undo_BeginBlock()

for i=0, sel_count-1 do
  local item = reaper.GetSelectedMediaItem(0, i)
  local len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
  -- Shrink right edge = diminuer longueur
  if delta > len then delta = len end -- éviter longueur négative
  reaper.SetMediaItemInfo_Value(item, "D_LENGTH", len - delta)
end

reaper.Undo_EndBlock("Shrink Right Edge (Nudge)", -1)

