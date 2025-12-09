--[[
@description Grow (Untrim) Right Edge of Selected Items by Nudge Value (reads timecode from PRE-POST-ROLL ImGui panel)
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-12-09)
  - Initial release (extends right edge of selected items based on TimecodeUI value)
@provides
  [main] ProTools_Essentials/GrowRightEdge-TCui.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags editing, nudge, item, trim, transport, (protools-like)
@about
  # Grow (Untrim) Right Edge of Selected Items (ProTools-like)
  
  This script moves the **right edge** of each selected media item forward
  by a duration defined in the companion **Unified PRE-POST-ROLL + Timecode UI (ImGui)** panel.
  
  ## 🟦 Timecode Input (Shared Setting)
  The nudge amount is read from the shared ExtState:
  
  - Namespace: **"TimecodeUI"**  
  - Key: **"tc"**  
  - Format: `HH:MM:SS:FF` (frames based; currently 25 fps)
  
  This value is written dynamically by:
  
  **PRE-POST-ROLL + Timecode UI (No Title, Draggable)**
  
  Using this shared timecode ensures consistent behavior across all
  ProTools-like editing and navigation scripts.
  
  ## 🟩 Usage
  - Only affects **selected items**.  
  - Moves the right edge of each item forward by the Timecode value (untrimming / extending the item).  
  - Undo is fully supported via REAPER's undo system.
  
  ## 🔗 Part of the ProTools_Essentials Suite
  Works in conjunction with:
  
  - Grow Left Edge  
  - Nudge Forward / Backward  
  - Nudge Forward ×10 / Backward ×10  
  - PRE-POST-ROLL + Timecode UI (ImGui)  
  - Set_Rolls_And_Nudge_Settings  
  - Other transport and editing tools
  
  Together, these scripts provide a unified, Pro Tools–style editing workflow in REAPER.
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
  -- Grow right edge = augmenter longueur
  reaper.SetMediaItemInfo_Value(item, "D_LENGTH", len + delta)
end

reaper.Undo_EndBlock("Grow Right Edge (Nudge)", -1)

