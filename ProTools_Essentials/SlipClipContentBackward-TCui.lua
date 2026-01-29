--[[
@description Slip Clip Content BACKWARD by Nudge Value (TimecodeUI)
@version 1.0
@author Mariow
@changelog
    v1.0 (2025-12-09)
    - Initial release (slips item contents backward using TimecodeUI nudge value)
@provides
    [main] ProTools_Essentials/SlipClipContentBackward-TCui.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags editing, slip, item, waveform, nudge, (protools-like)
@about
    # Slip Clip Content BACKWARD by Nudge Value
    
    Slips the **audio content (waveform)** inside selected items **backward**
    without moving the items themselves, according to the nudge value defined
    in the shared **TimecodeUI** panel.
    
    ## 🟦 Timecode Input (Shared Setting)
    - Namespace: **"TimecodeUI"**
    - Key: **"tc"**
    - Format: `HH:MM:SS:FF` (frames, 25 fps)
    
    ## 🟩 Usage
    - Moves item contents backward by the nudge value.
    - Works on all selected items.
    - Item position remains unchanged (classic *slip* behavior).
    - Undo supported via REAPER's undo system.
    
    ## 🔗 Part of the ProTools_Essentials Suite
    Works in combination with:
    
    - Slip Clip Content Forward  
    - Nudge Forward / Backward  
    - Move Time Selection scripts  
    - Razor Area editing tools  
    - Timecode UI (ImGui)  
    
    These scripts provide a unified, Pro Tools–inspired editing workflow in REAPER.
--]]

local function read_tc()
  local tc = reaper.GetExtState('TimecodeUI', 'tc')
  if not tc or tc == '' then return 0 end

  local h, m, s, f = tc:match('(%d+):(%d+):(%d+):(%d+)')
  if not h then return 0 end

  local fps = 25
  return h*3600 + m*60 + s + (f / fps)
end

local function slip_backward()
  local delta = read_tc()
  if delta == 0 then return end

  reaper.Undo_BeginBlock()

  local count = reaper.CountSelectedMediaItems(0)
  for i = 0, count - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    local take = reaper.GetActiveTake(item)
    if take then
      local offs = reaper.GetMediaItemTakeInfo_Value(take, 'D_STARTOFFS')
      reaper.SetMediaItemTakeInfo_Value(take, 'D_STARTOFFS', offs + delta)
    end
  end

  reaper.UpdateArrange()
  reaper.Undo_EndBlock('Slip Backward (Waveform)', -1)
end

slip_backward()
