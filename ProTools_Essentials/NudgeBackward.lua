--[[
@description Nudge Backward (reads timecode from PRE-POST-ROLL ImGui panel)
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-06-07)
  - Initial release (reads tc value from Unified PRE-POST-ROLL panel)
@provides
  [main] ProTools_Essentials/NudgeBackward.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags editing, nudge, cursor, items, transport, (protools-like)
@about
  # Nudge Backward (ProTools-like)
  
  This script moves the **edit cursor** or **selected items** backward by a duration
  defined in the companion **Unified PRE-POST-ROLL + Timecode UI (ImGui)** panel.
  
  ## 🟦 Timecode Input (Shared Setting)
  The nudge amount is read from a shared ExtState:
  
  - Namespace: **"TimecodeUI"**  
  - Key: **"tc"**  
  - Format: `HH:MM:SS:FF` (frames based; currently 25 fps)
  
  This value is written by the companion UI script:
  
  **PRE-POST-ROLL + Timecode UI (No Title, Draggable)**
  
  This makes the nudge system fully centralized and consistent across the
  ProTools-like workflow.
  
  ## 🟩 Usage
  - If one or more items are selected → those items are nudged backward.  
  - If no item is selected → the edit cursor is nudged backward.
  
  ## 🔗 Part of the ProTools_Essentials Suite
  This script works in conjunction with:
  
  - Nudge Forward  
  - PRE-POST-ROLL + Timecode UI (ImGui)  
  - Set_Rolls_And_Nudge_Settings  
  - Other transport/navigation tools in the suite
  
  Together they provide a unified, Pro Tools–like editing experience in REAPER.
--]]


local function read_tc()
  local tc = reaper.GetExtState('TimecodeUI','tc')
  if not tc or tc == '' then return 0 end
  local h, m, s, f = tc:match('(%d+):(%d+):(%d+):(%d+)')
  if not h then return 0 end
  local fps = 25
  local sr = reaper.GetSetProjectInfo(0,'PROJECT_SRATE',0,false)
  local total_seconds = h*3600 + m*60 + s + f/fps
  return total_seconds
end

local function move_backward()
  local delta = read_tc()
  if delta == 0 then return end
  reaper.Undo_BeginBlock()

  local sel_count = reaper.CountSelectedMediaItems(0)
  if sel_count > 0 then
    for i = 0, sel_count - 1 do
      local item = reaper.GetSelectedMediaItem(0, i)
      local pos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
      reaper.SetMediaItemInfo_Value(item, 'D_POSITION', pos - delta)
    end
  else
    local cur = reaper.GetCursorPosition()
    reaper.SetEditCurPos(cur - delta, true, false)
  end

  reaper.Undo_EndBlock('Nudge Backward', -1)
end

move_backward()
