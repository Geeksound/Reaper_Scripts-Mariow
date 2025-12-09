--[[
@description Nudge Forward x10 (reads timecode from PRE-POST-ROLL ImGui panel)
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-06-07)
  - Initial release (multiplies timecode nudge by 10)
@provides
  [main] ProTools_Essentials/NudgeForwardx10.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags editing, nudge, cursor, items, transport, (protools-like)
@about
  # Nudge Forward ×10 (ProTools-like)
  
  This script moves the **edit cursor** or **selected items** forward by a duration
  derived from the companion **Unified PRE-POST-ROLL + Timecode UI (ImGui)** panel,
  but scaled by a factor of **×10** for fast, coarse navigation.
  
  ## 🟦 Timecode Input (Shared Setting)
  The base nudge amount is read from the shared ExtState:
  
  - Namespace: **"TimecodeUI"**  
  - Key: **"tc"**  
  - Format: `HH:MM:SS:FF`
  
  This value is written dynamically by:
  
  **PRE-POST-ROLL + Timecode UI (No Title, Draggable)**
  
  The script multiplies this value by **10**, allowing rapid forward movement while
  maintaining full integration with the ProTools-like workflow.
  
  ## 🟩 Usage
  - If items are selected → they are nudged forward by (tc × 10).  
  - If no item is selected → the edit cursor is nudged forward by (tc × 10).
  
  ## 🔗 Part of the ProTools_Essentials Suite
  Works in conjunction with:
  
  - Nudge Backward  
  - Nudge Forward  
  - Nudge Backward ×10  
  - PRE-POST-ROLL + Timecode UI (ImGui)  
  - Set_Rolls_And_Nudge_Settings  
  - Other transport/navigation scripts
  
  Together, these tools create a consistent, Pro Tools–inspired editing workflow
  within REAPER.
--]]


local function read_tc()
  local tc = reaper.GetExtState('TimecodeUI','tc')
  if not tc or tc == '' then return 0 end
  local h, m, s, f = tc:match('(%d+):(%d+):(%d+):(%d+)')
  if not h then return 0 end
  local fps = 25
  local total_seconds = h*3600 + m*60 + s + f/fps
  return total_seconds * 10 -- ⟵ MULTIPLIÉ PAR 10
end

local function move_forward()
  local delta = read_tc()
  if delta == 0 then return end
  reaper.Undo_BeginBlock()

  local sel_count = reaper.CountSelectedMediaItems(0)
  if sel_count > 0 then
    for i = 0, sel_count - 1 do
      local item = reaper.GetSelectedMediaItem(0, i)
      local pos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
      reaper.SetMediaItemInfo_Value(item, 'D_POSITION', pos + delta)
    end
  else
    local cur = reaper.GetCursorPosition()
    reaper.SetEditCurPos(cur + delta, true, false)
  end

  reaper.Undo_EndBlock('Nudge Forward x10', -1)
end

move_forward()

